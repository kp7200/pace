import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.canvasCream,
      primaryColor: AppColors.inkBlack,
      canvasColor: AppColors.canvasCream,
      
      // Default Typography Base
      textTheme: const TextTheme(
        displayLarge: TextStyle(color: AppColors.inkBlack, fontWeight: FontWeight.bold),
        displayMedium: TextStyle(color: AppColors.inkBlack, fontWeight: FontWeight.bold),
        titleLarge: TextStyle(color: AppColors.inkBlack, fontWeight: FontWeight.w700),
        bodyLarge: TextStyle(color: AppColors.inkBlack, fontWeight: FontWeight.normal),
        bodyMedium: TextStyle(color: AppColors.inkBlack, fontWeight: FontWeight.normal),
      ),
      
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.canvasCream,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: AppColors.inkBlack),
        titleTextStyle: TextStyle(
          color: AppColors.inkBlack, 
          fontSize: 20, 
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.inkBlack,
      primaryColor: AppColors.canvasCream,
      canvasColor: AppColors.inkBlack,
      
      // Default Typography Base
      textTheme: const TextTheme(
        displayLarge: TextStyle(color: AppColors.canvasCream, fontWeight: FontWeight.bold),
        displayMedium: TextStyle(color: AppColors.canvasCream, fontWeight: FontWeight.bold),
        titleLarge: TextStyle(color: AppColors.canvasCream, fontWeight: FontWeight.w700),
        bodyLarge: TextStyle(color: AppColors.canvasCream, fontWeight: FontWeight.normal),
        bodyMedium: TextStyle(color: AppColors.canvasCream, fontWeight: FontWeight.normal),
      ),
      
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.inkBlack,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: AppColors.canvasCream),
        titleTextStyle: TextStyle(
          color: AppColors.canvasCream, 
          fontSize: 20, 
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
