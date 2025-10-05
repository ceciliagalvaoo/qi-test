import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../utils/theme.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    if (mounted) setState(() {
      _isLoading = true;
      _errorMessage = null; // Limpar erro anterior
    });

    final authProvider = context.read<AuthProvider>();
    final result = await authProvider.login(
      _emailController.text.trim(),
      _passwordController.text,
    );

    if (mounted) setState(() => _isLoading = false);

    if (mounted) {
      if (result['success']) {
        // Login bem-sucedido
        setState(() => _errorMessage = null);
        
        context.go('/dashboard');
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Login realizado com sucesso!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      } else {
        // Login falhou - definir mensagem de erro específica
        String errorMsg = 'Erro ao fazer login';
        
        final error = result['error']?.toString().toLowerCase() ?? '';
        
        if (error.contains('invalid') || error.contains('incorrect') || 
            error.contains('wrong') || error.contains('inválid')) {
          errorMsg = 'Email ou senha incorretos. Verifique seus dados e tente novamente.';
        } else if (error.contains('not found') || error.contains('não encontrado')) {
          errorMsg = 'Usuário não encontrado. Verifique o email digitado.';
        } else if (error.contains('password') || error.contains('senha')) {
          errorMsg = 'Senha incorreta. Tente novamente.';
        } else if (error.contains('network') || error.contains('connection')) {
          errorMsg = 'Erro de conexão. Verifique sua internet e tente novamente.';
        } else if (error.isNotEmpty) {
          errorMsg = result['error'];
        }
        
        setState(() => _errorMessage = errorMsg);
        
        // Também mostrar SnackBar para feedback imediato
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMsg),
            backgroundColor: AppColors.error,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                const Spacer(),
                
                // Logo e título
                Column(
                  children: [
                    // Logo da QiTech
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: Image.asset(
                          'assets/images/logo_qitech.png',
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    const Text(
                      'Bem-vindo de volta ao The Simple Split',
                      style: AppTextStyles.title1,
                      textAlign: TextAlign.center,
                    ),
                    
                    const SizedBox(height: 8),
                    
                    Text(
                      'Entre com sua conta para continuar',
                      style: AppTextStyles.subheadline.copyWith(
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 48),
                
                // Campos do formulário
                Column(
                  children: [
                    // Email
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      autofocus: false,
                      onChanged: (value) {
                        // Limpar erro quando usuário começar a digitar
                        if (_errorMessage != null) {
                          setState(() => _errorMessage = null);
                        }
                      },
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        hintText: 'seu@email.com',
                        prefixIcon: Icon(Icons.email_outlined),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Email é obrigatório';
                        }
                        if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                          return 'Email inválido';
                        }
                        return null;
                      },
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Senha
                    TextFormField(
                      controller: _passwordController,
                      obscureText: !_isPasswordVisible,
                      onChanged: (value) {
                        // Limpar erro quando usuário começar a digitar
                        if (_errorMessage != null) {
                          setState(() => _errorMessage = null);
                        }
                      },
                      decoration: InputDecoration(
                        labelText: 'Senha',
                        hintText: 'Digite sua senha',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _isPasswordVisible 
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                          ),
                          onPressed: () {
                            setState(() {
                              _isPasswordVisible = !_isPasswordVisible;
                            });
                          },
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Senha é obrigatória';
                        }
                        return null;
                      },
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Container de erro
                    if (_errorMessage != null) ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.error.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: AppColors.error.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.error_outline,
                              color: AppColors.error,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _errorMessage!,
                                style: TextStyle(
                                  color: AppColors.error,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    
                    // Botão de Login
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _handleLogin,
                        child: _isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              )
                            : const Text('Entrar'),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 24),
                
                // Link para registro
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Não tem uma conta? ',
                      style: AppTextStyles.subheadline.copyWith(
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                    TextButton(
                      onPressed: () => context.go('/auth/register'),
                      child: const Text('Criar conta'),
                    ),
                  ],
                ),
                
                const Spacer(),
                
                // Versão
                Text(
                  'v1.0.0',
                  style: AppTextStyles.caption2.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
                
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}