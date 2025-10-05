from app import db
from app.models.log import Log
from app.models.debt import Debt
from app.models.user import User, GroupMember
from collections import defaultdict

class LogService:
    @staticmethod
    def create_payment_log(debt):
        """Cria log de pagamento"""
        log = Log(
            type='payment',
            description=f"{debt.debtor.name} pagou R${debt.amount:.2f} para {debt.creditor.name}",
            user_id=debt.debtor_id,
            group_id=debt.expense.group_id if debt.expense else None,
            amount=debt.amount
        )
        db.session.add(log)
    
    @staticmethod
    def create_cancellation_log(debt):
        """Cria log de cancelamento"""
        log = Log(
            type='cancellation',
            description=f"Dívida de R${debt.amount:.2f} entre {debt.debtor.name} e {debt.creditor.name} foi cancelada",
            user_id=debt.debtor_id,
            group_id=debt.expense.group_id if debt.expense else None,
            amount=debt.amount
        )
        db.session.add(log)
    
    @staticmethod
    def create_optimization_log(debts_optimized, group_id=None):
        """Cria log de otimização de dívidas"""
        total_amount = sum([debt.amount for debt in debts_optimized])
        log = Log(
            type='optimization',
            description=f"Otimização automática cancelou R${total_amount:.2f} em dívidas cruzadas",
            group_id=group_id,
            amount=total_amount
        )
        db.session.add(log)
    
    @staticmethod
    def optimize_debts():
        """
        Otimiza dívidas encontrando ciclos e cancelando dívidas cruzadas
        Exemplo: A deve B, B deve C, C deve A -> todos quitados se valores iguais
        """
        # Buscar todas as dívidas pendentes (excluindo vendidas)
        pending_debts = Debt.get_pending_debts().all()
        
        # Agrupar por grupo para otimização local
        debts_by_group = defaultdict(list)
        for debt in pending_debts:
            if debt.expense and debt.expense.group:
                debts_by_group[debt.expense.group_id].append(debt)
        
        optimized_count = 0
        
        # Otimizar dentro de cada grupo
        for group_id, group_debts in debts_by_group.items():
            optimized_count += LogService._optimize_group_debts(group_debts, group_id)
        
        # Otimizar entre grupos (dívidas cruzadas entre usuários)
        optimized_count += LogService._optimize_cross_group_debts(pending_debts)
        
        if optimized_count > 0:
            db.session.commit()
        
        return optimized_count
    
    @staticmethod
    def _optimize_group_debts(debts, group_id):
        """Otimiza dívidas dentro de um grupo específico"""
        # Criar matriz de dívidas entre usuários
        debt_matrix = defaultdict(lambda: defaultdict(float))
        
        for debt in debts:
            debt_matrix[debt.debtor_id][debt.creditor_id] += debt.amount
        
        optimized = []
        
        # Encontrar e cancelar dívidas bidirecionais
        users = list(debt_matrix.keys())
        for i, user1 in enumerate(users):
            for user2 in users[i+1:]:
                debt1to2 = debt_matrix[user1][user2]
                debt2to1 = debt_matrix[user2][user1]
                
                if debt1to2 > 0 and debt2to1 > 0:
                    # Cancelar o menor valor
                    min_debt = min(debt1to2, debt2to1)
                    
                    # Encontrar e cancelar as dívidas reais
                    debts_to_cancel = []
                    remaining = min_debt
                    
                    for debt in debts:
                        if remaining <= 0:
                            break
                        if ((debt.debtor_id == user1 and debt.creditor_id == user2) or 
                            (debt.debtor_id == user2 and debt.creditor_id == user1)):
                            if debt.amount <= remaining:
                                debts_to_cancel.append(debt)
                                remaining -= debt.amount
                    
                    for debt in debts_to_cancel:
                        debt.cancel()
                        optimized.append(debt)
        
        if optimized:
            LogService.create_optimization_log(optimized, group_id)
        
        return len(optimized)
    
    @staticmethod
    def _optimize_cross_group_debts(all_debts):
        """Otimiza dívidas entre grupos diferentes"""
        # Agrupar dívidas por par de usuários
        user_debts = defaultdict(float)
        debt_objects = defaultdict(list)
        
        for debt in all_debts:
            key = tuple(sorted([debt.debtor_id, debt.creditor_id]))
            if debt.debtor_id < debt.creditor_id:
                user_debts[key] += debt.amount
            else:
                user_debts[key] -= debt.amount
            debt_objects[key].append(debt)
        
        optimized = []
        
        for (user1, user2), net_debt in user_debts.items():
            if abs(net_debt) < 0.01:  # Praticamente zero
                # Cancelar todas as dívidas entre esses usuários
                for debt in debt_objects[(user1, user2)]:
                    debt.cancel()
                    optimized.append(debt)
        
        if optimized:
            LogService.create_optimization_log(optimized)
        
        return len(optimized)