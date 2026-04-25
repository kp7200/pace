import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../base_controller.dart';
import '../widgets/common_loader.dart';

abstract class BaseView<T extends BaseController> extends GetView<T> {
  const BaseView({super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: safeArea() ? buildAppBar() : null,
        body: SafeArea(
          top: safeArea(),
          bottom: safeArea(),
          child: Stack(
            children: [
              buildBody(context),
              Obx(() => controller.isLoading.value 
                  ? const CommonLoader() 
                  : const SizedBox.shrink()),
            ],
          ),
        ),
        bottomNavigationBar: buildBottomNavigationBar(),
        floatingActionButton: buildFloatingActionButton(),
      ),
    );
  }

  /// Override this to build the main body of the view
  Widget buildBody(BuildContext context);

  /// Optional AppBar
  PreferredSizeWidget? buildAppBar() => null;

  /// Optional BottomNavigationBar
  Widget? buildBottomNavigationBar() => null;

  /// Optional FloatingActionButton
  Widget? buildFloatingActionButton() => null;

  /// Override to false if you want to handle SafeArea manually
  bool safeArea() => true;
}
