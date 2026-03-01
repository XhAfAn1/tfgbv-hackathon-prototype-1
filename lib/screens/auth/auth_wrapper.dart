import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../mobile/mobile_home.dart';
import '../web/web_dashboard.dart';
import 'login_screen.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = context.watch<AuthService>();
    
    // Show a loading indicator while the initial auth state is being determined
    if (!authService.isInit || (authService.isLoading && authService.currentUser == null)) {
       return const Scaffold(
         body: Center(
           child: CircularProgressIndicator(color: Colors.lightBlue),
         ),
       );
    }

    if (authService.currentUser == null) {
      return const LoginScreen();
    }
    
    // Check role to route properly
    if (authService.currentUser!.role == 'ngo') {
      return LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth < 600) {
            return const WebAdminDashboard();
          }
          return const WebAdminDashboard();
        },
      );
    }
    
    return LayoutBuilder(
      builder: (context, constraints) {
        return const MobileMainLayout();
      }
    );
  }
}
