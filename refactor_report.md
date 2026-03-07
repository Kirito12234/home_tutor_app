# Home Tutor App Refactor Report

Generated: 2026-03-07 11:25:35

## Notes
- Goal: cleaner clean-architecture layout while preserving functionality (routes/Riverpod/Hive).
- `flutter test` passes; `flutter analyze` reports existing lint infos/warnings.

## Moved files
- `lib/features/student_courses/data/models/dummy_courses.dart` → `lib/features/student_courses/data/dummy/dummy_courses.dart`

## New files (architecture wiring)
- `lib/core/services/connectivity/connectivity_service.dart`
- Auth (Clean Architecture + Riverpod wiring)
  - `lib/features/auth/domain/entities/auth_session.dart`
  - `lib/features/auth/domain/entities/auth_user.dart`
  - `lib/features/auth/domain/repositories/auth_repository.dart`
  - `lib/features/auth/data/models/auth_user_model.dart`
  - `lib/features/auth/data/datasources/local/auth_local_datasource.dart`
  - `lib/features/auth/data/datasources/remote/auth_remote_datasource.dart`
  - `lib/features/auth/data/repositories/auth_repository_impl.dart`
  - `lib/features/auth/presentation/view_model/auth_state.dart`
  - `lib/features/auth/presentation/view_model/auth_view_model.dart`
  - `lib/features/auth/presentation/providers/auth_providers.dart`
- Notifications (Repository + ViewModel + Providers)
  - `lib/features/notifications/domain/repositories/notifications_repository.dart`
  - `lib/features/notifications/data/datasources/local/notifications_local_datasource.dart`
  - `lib/features/notifications/data/datasources/remote/notifications_remote_datasource.dart`
  - `lib/features/notifications/data/repositories/notifications_repository_impl.dart`
  - `lib/features/notifications/presentation/view_model/notifications_state.dart`
  - `lib/features/notifications/presentation/view_model/notifications_view_model.dart`
  - `lib/features/notifications/presentation/providers/notifications_provider.dart`
- Student courses (Repository + ViewModel + Providers + centralized mapping)
  - `lib/features/student_courses/data/models/course_model.dart`
  - `lib/features/student_courses/data/datasources/local/student_courses_local_datasource.dart`
  - `lib/features/student_courses/data/datasources/remote/student_courses_remote_datasource.dart`
  - `lib/features/student_courses/data/repositories/student_courses_repository_impl.dart`
  - `lib/features/student_courses/domain/repositories/student_courses_repository.dart`
  - `lib/features/student_courses/presentation/view_model/course_catalog_state.dart`
  - `lib/features/student_courses/presentation/view_model/course_catalog_view_model.dart`
  - `lib/features/student_courses/presentation/providers/student_courses_provider.dart`
- Teacher chat (model extraction)
  - `lib/features/chat/presentation/view_model/teacher_messages_models.dart`

## Renamed files
- None

## Deleted duplicate/unused files
- None (the `dummy_courses.dart` change is treated as a move; the original path is removed).

## Key files left unchanged (behavior/contracts)
- Existing route names/navigation behavior preserved (no renames; `AppRoutes` only has additive changes in this working tree).
- App entrypoint in `lib/main.dart` (still calls `HiveService.init()` before `runApp(ProviderScope(...))`).

## Manual review items
- Consider addressing existing `flutter analyze` warnings/infos (e.g., `unused_element_parameter` in `lib/features/teacher_dashboard/presentation/pages/teacher_home_page.dart`).
- Many features still have placeholder `.gitkeep` files; safe to remove only after directories contain real files and you prefer a cleaner tree.

## Final `lib/` tree
```
Folder PATH listing
Volume serial number is 5EF5-CF3D
C:\FLUTTER\HOMETUTORAPP\LIB
�   main.dart
�   
+---app
�   �   app.dart
�   �   
�   +---routes
�   �       app_routes.dart
�   �       
�   +---theme
�           app_colors.dart
�           app_theme.dart
�           theme_extensions.dart
�           
+---core
�   �   .gitkeep
�   �   
�   +---api
�   �       api_client.dart
�   �       api_endpoints.dart
�   �       
�   +---config
�   �       .gitkeep
�   �       
�   +---constants
�   �       app_constants.dart
�   �       asset_paths.dart
�   �       learning_plan_courses.dart
�   �       user_display_name.dart
�   �       
�   +---error
�   �       .gitkeep
�   �       exceptions.dart
�   �       failures.dart
�   �       
�   +---extensions
�   �       .gitkeep
�   �       context_extensions.dart
�   �       
�   +---providers
�   �       .gitkeep
�   �       shared_prefs_provider.dart
�   �       
�   +---services
�   �   �   .gitkeep
�   �   �   
�   �   +---connectivity
�   �   �       .gitkeep
�   �   �       connectivity_service.dart
�   �   �       
�   �   +---emergency
�   �   �       emergency_alert_service.dart
�   �   �       
�   �   +---hive
�   �   �       hive_service.dart
�   �   �       
�   �   +---media
�   �   �       .gitkeep
�   �   �       
�   �   +---profile
�   �   �       user_profile_service.dart
�   �   �       
�   �   +---socket
�   �   �       socket_service.dart
�   �   �       
�   �   +---storage
�   �   �       .gitkeep
�   �   �       storage_service.dart
�   �   �       
�   �   +---sync
�   �   �       .gitkeep
�   �   �       
�   �   +---teacher
�   �           teacher_request_actions_service.dart
�   �           
�   +---utils
�   �       .gitkeep
�   �       file_download.dart
�   �       file_download_io.dart
�   �       file_download_stub.dart
�   �       material_file_utils.dart
�   �       snackbar_utils.dart
�   �       
�   +---widgets
�           app_text_field.dart
�           file_picker_screen.dart
�           gradient_button.dart
�           page_dots.dart
�           pdf_viewer_page.dart
�           platform_file_image.dart
�           platform_file_image_io.dart
�           platform_file_image_stub.dart
�           primary_button.dart
�           profile_avatar.dart
�           social_button.dart
�           video_viewer_page.dart
�           
+---features
�   �   .gitkeep
�   �   
�   +---auth
�   �   �   .gitkeep
�   �   �   
�   �   +---data
�   �   �   �   .gitkeep
�   �   �   �   
�   �   �   +---datasources
�   �   �   �   �   .gitkeep
�   �   �   �   �   
�   �   �   �   +---local
�   �   �   �   �       .gitkeep
�   �   �   �   �       auth_local_datasource.dart
�   �   �   �   �       
�   �   �   �   +---remote
�   �   �   �           .gitkeep
�   �   �   �           auth_remote_datasource.dart
�   �   �   �           
�   �   �   +---models
�   �   �   �       .gitkeep
�   �   �   �       auth_user_model.dart
�   �   �   �       
�   �   �   +---repositories
�   �   �   �       .gitkeep
�   �   �   �       auth_repository_impl.dart
�   �   �   �       
�   �   �   +---schemas
�   �   �           .gitkeep
�   �   �           
�   �   +---domain
�   �   �   �   .gitkeep
�   �   �   �   
�   �   �   +---entities
�   �   �   �       .gitkeep
�   �   �   �       auth_session.dart
�   �   �   �       auth_user.dart
�   �   �   �       
�   �   �   +---repositories
�   �   �   �       .gitkeep
�   �   �   �       auth_repository.dart
�   �   �   �       
�   �   �   +---usecases
�   �   �           .gitkeep
�   �   �           
�   �   +---presentation
�   �       �   .gitkeep
�   �       �   
�   �       +---pages
�   �       �       forgot_password_page.dart
�   �       �       login_page.dart
�   �       �       phone_continue_page.dart
�   �       �       phone_verify_page.dart
�   �       �       role_select_page.dart
�   �       �       signup_page.dart
�   �       �       success_page.dart
�   �       �       
�   �       +---providers
�   �       �       .gitkeep
�   �       �       auth_providers.dart
�   �       �       
�   �       +---view_model
�   �       �       .gitkeep
�   �       �       auth_state.dart
�   �       �       auth_view_model.dart
�   �       �       
�   �       +---widgets
�   �               .gitkeep
�   �               
�   +---chat
�   �   �   .gitkeep
�   �   �   
�   �   +---data
�   �   �   �   .gitkeep
�   �   �   �   
�   �   �   +---datasources
�   �   �   �   �   .gitkeep
�   �   �   �   �   
�   �   �   �   +---local
�   �   �   �   �       .gitkeep
�   �   �   �   �       
�   �   �   �   +---remote
�   �   �   �           .gitkeep
�   �   �   �           
�   �   �   +---models
�   �   �   �       .gitkeep
�   �   �   �       
�   �   �   +---repositories
�   �   �   �       .gitkeep
�   �   �   �       
�   �   �   +---schemas
�   �   �           .gitkeep
�   �   �           
�   �   +---domain
�   �   �   �   .gitkeep
�   �   �   �   
�   �   �   +---entities
�   �   �   �       .gitkeep
�   �   �   �       
�   �   �   +---repositories
�   �   �   �       .gitkeep
�   �   �   �       
�   �   �   +---usecases
�   �   �           .gitkeep
�   �   �           
�   �   +---presentation
�   �       �   .gitkeep
�   �       �   
�   �       +---pages
�   �       �       teacher_messages_page.dart
�   �       �       
�   �       +---providers
�   �       �       .gitkeep
�   �       �       
�   �       +---view_model
�   �       �       .gitkeep
�   �       �       teacher_messages_models.dart
�   �       �       
�   �       +---widgets
�   �               .gitkeep
�   �               
�   +---notifications
�   �   �   .gitkeep
�   �   �   
�   �   +---data
�   �   �   �   .gitkeep
�   �   �   �   
�   �   �   +---datasources
�   �   �   �   �   .gitkeep
�   �   �   �   �   
�   �   �   �   +---local
�   �   �   �   �       .gitkeep
�   �   �   �   �       notifications_local_datasource.dart
�   �   �   �   �       
�   �   �   �   +---remote
�   �   �   �           .gitkeep
�   �   �   �           notifications_remote_datasource.dart
�   �   �   �           
�   �   �   +---dummy
�   �   �   �       dummy_notifications.dart
�   �   �   �       
�   �   �   +---models
�   �   �   �       .gitkeep
�   �   �   �       
�   �   �   +---repositories
�   �   �   �       .gitkeep
�   �   �   �       notifications_repository_impl.dart
�   �   �   �       
�   �   �   +---schemas
�   �   �           .gitkeep
�   �   �           
�   �   +---domain
�   �   �   �   .gitkeep
�   �   �   �   
�   �   �   +---entities
�   �   �   �       message_notification.dart
�   �   �   �       
�   �   �   +---repositories
�   �   �   �       .gitkeep
�   �   �   �       notifications_repository.dart
�   �   �   �       
�   �   �   +---usecases
�   �   �           .gitkeep
�   �   �           
�   �   +---presentation
�   �       �   .gitkeep
�   �       �   
�   �       +---pages
�   �       �       message_thread_page.dart
�   �       �       notifications_page.dart
�   �       �       no_network_page.dart
�   �       �       no_notifications_page.dart
�   �       �       
�   �       +---providers
�   �       �       .gitkeep
�   �       �       notifications_provider.dart
�   �       �       
�   �       +---view_model
�   �       �       .gitkeep
�   �       �       notifications_state.dart
�   �       �       notifications_view_model.dart
�   �       �       
�   �       +---widgets
�   �               message_card.dart
�   �               notification_tile.dart
�   �               segmented_tabs.dart
�   �               
�   +---onboarding
�   �   �   .gitkeep
�   �   �   
�   �   +---data
�   �   �   �   .gitkeep
�   �   �   �   
�   �   �   +---datasources
�   �   �   �   �   .gitkeep
�   �   �   �   �   
�   �   �   �   +---local
�   �   �   �   �       .gitkeep
�   �   �   �   �       
�   �   �   �   +---remote
�   �   �   �           .gitkeep
�   �   �   �           
�   �   �   +---models
�   �   �   �       .gitkeep
�   �   �   �       
�   �   �   +---repositories
�   �   �   �       .gitkeep
�   �   �   �       
�   �   �   +---schemas
�   �   �           .gitkeep
�   �   �           
�   �   +---domain
�   �   �   �   .gitkeep
�   �   �   �   
�   �   �   +---entities
�   �   �   �       .gitkeep
�   �   �   �       
�   �   �   +---repositories
�   �   �   �       .gitkeep
�   �   �   �       
�   �   �   +---usecases
�   �   �           .gitkeep
�   �   �           
�   �   +---presentation
�   �       �   .gitkeep
�   �       �   
�   �       +---pages
�   �       �       onboarding_page.dart
�   �       �       
�   �       +---providers
�   �       �       .gitkeep
�   �       �       
�   �       +---view_model
�   �       �       .gitkeep
�   �       �       
�   �       +---widgets
�   �               .gitkeep
�   �               
�   +---sensors
�   �   +---data
�   �   �   +---datasources
�   �   �   �       sensor_datasource.dart
�   �   �   �       
�   �   �   +---repositories
�   �   �           sensor_repository_impl.dart
�   �   �           
�   �   +---domain
�   �   �   +---entities
�   �   �   �       sensor_event.dart
�   �   �   �       
�   �   �   +---repositories
�   �   �           sensor_repository.dart
�   �   �           
�   �   +---presentation
�   �       +---pages
�   �       �       sensor_diagnostics_page.dart
�   �       �       
�   �       +---providers
�   �       �       sensor_provider.dart
�   �       �       
�   �       +---view_model
�   �       �       sensor_state.dart
�   �       �       sensor_view_model.dart
�   �       �       
�   �       +---widgets
�   �               emergency_shake_listener.dart
�   �               sensor_warning_widget.dart
�   �               
�   +---splash
�   �   �   .gitkeep
�   �   �   
�   �   +---data
�   �   �   �   .gitkeep
�   �   �   �   
�   �   �   +---datasources
�   �   �   �   �   .gitkeep
�   �   �   �   �   
�   �   �   �   +---local
�   �   �   �   �       .gitkeep
�   �   �   �   �       
�   �   �   �   +---remote
�   �   �   �           .gitkeep
�   �   �   �           
�   �   �   +---models
�   �   �   �       .gitkeep
�   �   �   �       
�   �   �   +---repositories
�   �   �   �       .gitkeep
�   �   �   �       
�   �   �   +---schemas
�   �   �           .gitkeep
�   �   �           
�   �   +---domain
�   �   �   �   .gitkeep
�   �   �   �   
�   �   �   +---entities
�   �   �   �       .gitkeep
�   �   �   �       
�   �   �   +---repositories
�   �   �   �       .gitkeep
�   �   �   �       
�   �   �   +---usecases
�   �   �           .gitkeep
�   �   �           
�   �   +---presentation
�   �       �   .gitkeep
�   �       �   
�   �       +---pages
�   �       �       .gitkeep
�   �       �       
�   �       +---providers
�   �       �       .gitkeep
�   �       �       
�   �       +---view_model
�   �       �       .gitkeep
�   �       �       
�   �       +---widgets
�   �               .gitkeep
�   �               
�   +---student_assignments
�   �   �   .gitkeep
�   �   �   
�   �   +---data
�   �   �   �   .gitkeep
�   �   �   �   
�   �   �   +---datasources
�   �   �   �   �   .gitkeep
�   �   �   �   �   
�   �   �   �   +---local
�   �   �   �   �       .gitkeep
�   �   �   �   �       
�   �   �   �   +---remote
�   �   �   �           .gitkeep
�   �   �   �           
�   �   �   +---models
�   �   �   �       .gitkeep
�   �   �   �       
�   �   �   +---repositories
�   �   �   �       .gitkeep
�   �   �   �       
�   �   �   +---schemas
�   �   �           .gitkeep
�   �   �           
�   �   +---domain
�   �   �   �   .gitkeep
�   �   �   �   
�   �   �   +---entities
�   �   �   �       .gitkeep
�   �   �   �       
�   �   �   +---repositories
�   �   �   �       .gitkeep
�   �   �   �       
�   �   �   +---usecases
�   �   �           .gitkeep
�   �   �           
�   �   +---presentation
�   �       �   .gitkeep
�   �       �   
�   �       +---pages
�   �       �       .gitkeep
�   �       �       
�   �       +---providers
�   �       �       .gitkeep
�   �       �       
�   �       +---view_model
�   �       �       .gitkeep
�   �       �       
�   �       +---widgets
�   �               .gitkeep
�   �               
�   +---student_attendance
�   �   �   .gitkeep
�   �   �   
�   �   +---data
�   �   �   �   .gitkeep
�   �   �   �   
�   �   �   +---datasources
�   �   �   �   �   .gitkeep
�   �   �   �   �   
�   �   �   �   +---local
�   �   �   �   �       .gitkeep
�   �   �   �   �       
�   �   �   �   +---remote
�   �   �   �           .gitkeep
�   �   �   �           
�   �   �   +---models
�   �   �   �       .gitkeep
�   �   �   �       
�   �   �   +---repositories
�   �   �   �       .gitkeep
�   �   �   �       
�   �   �   +---schemas
�   �   �           .gitkeep
�   �   �           
�   �   +---domain
�   �   �   �   .gitkeep
�   �   �   �   
�   �   �   +---entities
�   �   �   �       .gitkeep
�   �   �   �       
�   �   �   +---repositories
�   �   �   �       .gitkeep
�   �   �   �       
�   �   �   +---usecases
�   �   �           .gitkeep
�   �   �           
�   �   +---presentation
�   �       �   .gitkeep
�   �       �   
�   �       +---pages
�   �       �       clocking_in_modal.dart
�   �       �       
�   �       +---providers
�   �       �       .gitkeep
�   �       �       
�   �       +---view_model
�   �       �       .gitkeep
�   �       �       
�   �       +---widgets
�   �               week_record_dots.dart
�   �               
�   +---student_courses
�   �   �   .gitkeep
�   �   �   
�   �   +---data
�   �   �   �   .gitkeep
�   �   �   �   
�   �   �   +---datasources
�   �   �   �   �   .gitkeep
�   �   �   �   �   
�   �   �   �   +---local
�   �   �   �   �       .gitkeep
�   �   �   �   �       student_courses_local_datasource.dart
�   �   �   �   �       
�   �   �   �   +---remote
�   �   �   �           .gitkeep
�   �   �   �           student_courses_remote_datasource.dart
�   �   �   �           
�   �   �   +---dummy
�   �   �   �       dummy_courses.dart
�   �   �   �       
�   �   �   +---models
�   �   �   �       course_model.dart
�   �   �   �       
�   �   �   +---repositories
�   �   �   �       .gitkeep
�   �   �   �       student_courses_repository_impl.dart
�   �   �   �       
�   �   �   +---schemas
�   �   �           .gitkeep
�   �   �           
�   �   +---domain
�   �   �   �   .gitkeep
�   �   �   �   
�   �   �   +---entities
�   �   �   �       course.dart
�   �   �   �       
�   �   �   +---repositories
�   �   �   �       .gitkeep
�   �   �   �       student_courses_repository.dart
�   �   �   �       
�   �   �   +---usecases
�   �   �           .gitkeep
�   �   �           
�   �   +---presentation
�   �       �   .gitkeep
�   �       �   
�   �       +---pages
�   �       �       course_detail_page.dart
�   �       �       course_page.dart
�   �       �       course_player_page.dart
�   �       �       learning_plan_detail_page.dart
�   �       �       learning_plan_live_page.dart
�   �       �       learning_plan_message_page.dart
�   �       �       learning_plan_schedule_page.dart
�   �       �       learning_plan_video_page.dart
�   �       �       my_courses_page.dart
�   �       �       no_videos_page.dart
�   �       �       search_results_page.dart
�   �       �       
�   �       +---providers
�   �       �       .gitkeep
�   �       �       student_courses_provider.dart
�   �       �       
�   �       +---view_model
�   �       �       .gitkeep
�   �       �       course_catalog_state.dart
�   �       �       course_catalog_view_model.dart
�   �       �       
�   �       +---widgets
�   �               course_category_card.dart
�   �               course_list_item.dart
�   �               course_progress_tile.dart
�   �               duration_chip.dart
�   �               empty_state_view.dart
�   �               filter_sheet.dart
�   �               lesson_list_item.dart
�   �               my_courses_header.dart
�   �               price_range_slider.dart
�   �               
�   +---student_dashboard
�   �   �   .gitkeep
�   �   �   
�   �   +---data
�   �   �   �   .gitkeep
�   �   �   �   
�   �   �   +---datasources
�   �   �   �   �   .gitkeep
�   �   �   �   �   
�   �   �   �   +---local
�   �   �   �   �       .gitkeep
�   �   �   �   �       
�   �   �   �   +---remote
�   �   �   �           .gitkeep
�   �   �   �           
�   �   �   +---models
�   �   �   �       .gitkeep
�   �   �   �       
�   �   �   +---repositories
�   �   �   �       .gitkeep
�   �   �   �       
�   �   �   +---schemas
�   �   �           .gitkeep
�   �   �           
�   �   +---domain
�   �   �   �   .gitkeep
�   �   �   �   
�   �   �   +---entities
�   �   �   �       lesson.dart
�   �   �   �       
�   �   �   +---repositories
�   �   �   �       .gitkeep
�   �   �   �       
�   �   �   +---usecases
�   �   �           .gitkeep
�   �   �           
�   �   +---presentation
�   �       �   .gitkeep
�   �       �   
�   �       +---pages
�   �       �       home_page.dart
�   �       �       learn_today_page.dart
�   �       �       meetup_page.dart
�   �       �       no_products_page.dart
�   �       �       payment_method_page.dart
�   �       �       purchase_success_page.dart
�   �       �       
�   �       +---providers
�   �       �       .gitkeep
�   �       �       
�   �       +---view_model
�   �       �       .gitkeep
�   �       �       
�   �       +---widgets
�   �               bottom_nav.dart
�   �               header_greeting.dart
�   �               learned_today_card.dart
�   �               learning_plan_card.dart
�   �               learn_banner_card.dart
�   �               numeric_keypad.dart
�   �               payment_password_sheet.dart
�   �               pin_dots_row.dart
�   �               
�   +---student_profile
�   �   �   .gitkeep
�   �   �   
�   �   +---data
�   �   �   �   .gitkeep
�   �   �   �   
�   �   �   +---datasources
�   �   �   �   �   .gitkeep
�   �   �   �   �   
�   �   �   �   +---local
�   �   �   �   �       .gitkeep
�   �   �   �   �       
�   �   �   �   +---remote
�   �   �   �           .gitkeep
�   �   �   �           
�   �   �   +---models
�   �   �   �       .gitkeep
�   �   �   �       
�   �   �   +---repositories
�   �   �   �       .gitkeep
�   �   �   �       
�   �   �   +---schemas
�   �   �           .gitkeep
�   �   �           
�   �   +---domain
�   �   �   �   .gitkeep
�   �   �   �   
�   �   �   +---entities
�   �   �   �       .gitkeep
�   �   �   �       
�   �   �   +---repositories
�   �   �   �       .gitkeep
�   �   �   �       
�   �   �   +---usecases
�   �   �           .gitkeep
�   �   �           
�   �   +---presentation
�   �       �   .gitkeep
�   �       �   
�   �       +---pages
�   �       �       account_page.dart
�   �       �       favourite_page.dart
�   �       �       help_page.dart
�   �       �       settings_privacy_page.dart
�   �       �       
�   �       +---providers
�   �       �       .gitkeep
�   �       �       
�   �       +---view_model
�   �       �       .gitkeep
�   �       �       
�   �       +---widgets
�   �               .gitkeep
�   �               
�   +---teacher_assignments
�   �   �   .gitkeep
�   �   �   
�   �   +---data
�   �   �   �   .gitkeep
�   �   �   �   
�   �   �   +---datasources
�   �   �   �   �   .gitkeep
�   �   �   �   �   
�   �   �   �   +---local
�   �   �   �   �       .gitkeep
�   �   �   �   �       
�   �   �   �   +---remote
�   �   �   �           .gitkeep
�   �   �   �           
�   �   �   +---models
�   �   �   �       .gitkeep
�   �   �   �       
�   �   �   +---repositories
�   �   �   �       .gitkeep
�   �   �   �       
�   �   �   +---schemas
�   �   �           .gitkeep
�   �   �           
�   �   +---domain
�   �   �   �   .gitkeep
�   �   �   �   
�   �   �   +---entities
�   �   �   �       .gitkeep
�   �   �   �       
�   �   �   +---repositories
�   �   �   �       .gitkeep
�   �   �   �       
�   �   �   +---usecases
�   �   �           .gitkeep
�   �   �           
�   �   +---presentation
�   �       �   .gitkeep
�   �       �   
�   �       +---pages
�   �       �       teacher_manage_students_page.dart
�   �       �       teacher_requests_page.dart
�   �       �       teacher_share_invite_page.dart
�   �       �       
�   �       +---providers
�   �       �       .gitkeep
�   �       �       
�   �       +---view_model
�   �       �       .gitkeep
�   �       �       
�   �       +---widgets
�   �               .gitkeep
�   �               
�   +---teacher_attendance
�   �   �   .gitkeep
�   �   �   
�   �   +---data
�   �   �   �   .gitkeep
�   �   �   �   
�   �   �   +---datasources
�   �   �   �   �   .gitkeep
�   �   �   �   �   
�   �   �   �   +---local
�   �   �   �   �       .gitkeep
�   �   �   �   �       
�   �   �   �   +---remote
�   �   �   �           .gitkeep
�   �   �   �           
�   �   �   +---models
�   �   �   �       .gitkeep
�   �   �   �       
�   �   �   +---repositories
�   �   �   �       .gitkeep
�   �   �   �       
�   �   �   +---schemas
�   �   �           .gitkeep
�   �   �           
�   �   +---domain
�   �   �   �   .gitkeep
�   �   �   �   
�   �   �   +---entities
�   �   �   �       .gitkeep
�   �   �   �       
�   �   �   +---repositories
�   �   �   �       .gitkeep
�   �   �   �       
�   �   �   +---usecases
�   �   �           .gitkeep
�   �   �           
�   �   +---presentation
�   �       �   .gitkeep
�   �       �   
�   �       +---pages
�   �       �       teacher_schedule_session_page.dart
�   �       �       teacher_student_logins_page.dart
�   �       �       
�   �       +---providers
�   �       �       .gitkeep
�   �       �       
�   �       +---view_model
�   �       �       .gitkeep
�   �       �       
�   �       +---widgets
�   �               .gitkeep
�   �               
�   +---teacher_courses
�   �   �   .gitkeep
�   �   �   
�   �   +---data
�   �   �   �   .gitkeep
�   �   �   �   
�   �   �   +---datasources
�   �   �   �   �   .gitkeep
�   �   �   �   �   
�   �   �   �   +---local
�   �   �   �   �       .gitkeep
�   �   �   �   �       
�   �   �   �   +---remote
�   �   �   �           .gitkeep
�   �   �   �           
�   �   �   +---models
�   �   �   �       .gitkeep
�   �   �   �       
�   �   �   +---repositories
�   �   �   �       .gitkeep
�   �   �   �       
�   �   �   +---schemas
�   �   �           .gitkeep
�   �   �           
�   �   +---domain
�   �   �   �   .gitkeep
�   �   �   �   
�   �   �   +---entities
�   �   �   �       .gitkeep
�   �   �   �       
�   �   �   +---repositories
�   �   �   �       .gitkeep
�   �   �   �       
�   �   �   +---usecases
�   �   �           .gitkeep
�   �   �           
�   �   +---presentation
�   �       �   .gitkeep
�   �       �   
�   �       +---pages
�   �       �       teacher_courses_page.dart
�   �       �       teacher_course_detail_page.dart
�   �       �       teacher_course_overview_page.dart
�   �       �       teacher_create_course_page.dart
�   �       �       teacher_manage_curriculum_page.dart
�   �       �       
�   �       +---providers
�   �       �       .gitkeep
�   �       �       
�   �       +---view_model
�   �       �       .gitkeep
�   �       �       
�   �       +---widgets
�   �               .gitkeep
�   �               
�   +---teacher_dashboard
�   �   �   .gitkeep
�   �   �   
�   �   +---data
�   �   �   �   .gitkeep
�   �   �   �   
�   �   �   +---datasources
�   �   �   �   �   .gitkeep
�   �   �   �   �   
�   �   �   �   +---local
�   �   �   �   �       .gitkeep
�   �   �   �   �       
�   �   �   �   +---remote
�   �   �   �           .gitkeep
�   �   �   �           
�   �   �   +---models
�   �   �   �       .gitkeep
�   �   �   �       
�   �   �   +---repositories
�   �   �   �       .gitkeep
�   �   �   �       
�   �   �   +---schemas
�   �   �           .gitkeep
�   �   �           
�   �   +---domain
�   �   �   �   .gitkeep
�   �   �   �   
�   �   �   +---entities
�   �   �   �       .gitkeep
�   �   �   �       
�   �   �   +---repositories
�   �   �   �       .gitkeep
�   �   �   �       
�   �   �   +---usecases
�   �   �           .gitkeep
�   �   �           
�   �   +---presentation
�   �       �   .gitkeep
�   �       �   
�   �       +---pages
�   �       �       teacher_home_page.dart
�   �       �       teacher_professionals_page.dart
�   �       �       teacher_reports_page.dart
�   �       �       teacher_search_page.dart
�   �       �       
�   �       +---providers
�   �       �       .gitkeep
�   �       �       
�   �       +---view_model
�   �       �       .gitkeep
�   �       �       
�   �       +---widgets
�   �               teacher_bottom_nav.dart
�   �               
�   +---teacher_profile
�       �   .gitkeep
�       �   
�       +---data
�       �   �   .gitkeep
�       �   �   
�       �   +---datasources
�       �   �   �   .gitkeep
�       �   �   �   
�       �   �   +---local
�       �   �   �       .gitkeep
�       �   �   �       
�       �   �   +---remote
�       �   �           .gitkeep
�       �   �           
�       �   +---models
�       �   �       .gitkeep
�       �   �       
�       �   +---repositories
�       �   �       .gitkeep
�       �   �       
�       �   +---schemas
�       �           .gitkeep
�       �           
�       +---domain
�       �   �   .gitkeep
�       �   �   
�       �   +---entities
�       �   �       .gitkeep
�       �   �       
�       �   +---repositories
�       �   �       .gitkeep
�       �   �       
�       �   +---usecases
�       �           .gitkeep
�       �           
�       +---presentation
�           �   .gitkeep
�           �   
�           +---pages
�           �       teacher_account_page.dart
�           �       teacher_payout_settings_page.dart
�           �       teacher_student_profile_page.dart
�           �       
�           +---providers
�           �       .gitkeep
�           �       
�           +---view_model
�           �       .gitkeep
�           �       
�           +---widgets
�                   .gitkeep
�                   
+---l10n
        .gitkeep
```

## Git status (working tree)
```text
 M .metadata
 M android/app/src/main/AndroidManifest.xml
 M ios/Runner/Info.plist
 M lib/app/app.dart
 M lib/app/routes/app_routes.dart
 M lib/core/api/api_client.dart
 M lib/core/widgets/social_button.dart
 M lib/features/auth/presentation/pages/login_page.dart
 M lib/features/chat/presentation/pages/teacher_messages_page.dart
 M lib/features/notifications/presentation/pages/notifications_page.dart
 M lib/features/onboarding/presentation/pages/onboarding_page.dart
 M lib/features/sensors/presentation/view_model/sensor_state.dart
 M lib/features/sensors/presentation/view_model/sensor_view_model.dart
 D lib/features/student_courses/data/models/dummy_courses.dart
 M lib/features/student_courses/presentation/pages/course_detail_page.dart
 M lib/features/student_courses/presentation/pages/course_page.dart
 M lib/features/student_courses/presentation/pages/course_player_page.dart
 M lib/features/student_courses/presentation/pages/my_courses_page.dart
 M lib/features/student_courses/presentation/pages/search_results_page.dart
 M lib/features/student_courses/presentation/widgets/course_list_item.dart
 M lib/features/student_profile/presentation/pages/settings_privacy_page.dart
 M lib/features/teacher_attendance/presentation/pages/teacher_schedule_session_page.dart
 M lib/features/teacher_courses/presentation/pages/teacher_course_detail_page.dart
 M lib/features/teacher_courses/presentation/pages/teacher_courses_page.dart
 M lib/features/teacher_courses/presentation/pages/teacher_manage_curriculum_page.dart
 M lib/features/teacher_dashboard/presentation/pages/teacher_home_page.dart
 M pubspec.lock
 M pubspec.yaml
 M test/widget/login_page_ui_test.dart
 M test/widget/login_validation_test.dart
?? assets/icons/facebook.svg
?? assets/icons/google.svg
?? lib/core/services/connectivity/connectivity_service.dart
?? lib/core/services/emergency/
?? lib/features/auth/data/datasources/local/auth_local_datasource.dart
?? lib/features/auth/data/datasources/remote/auth_remote_datasource.dart
?? lib/features/auth/data/models/auth_user_model.dart
?? lib/features/auth/data/repositories/auth_repository_impl.dart
?? lib/features/auth/domain/entities/auth_session.dart
?? lib/features/auth/domain/entities/auth_user.dart
?? lib/features/auth/domain/repositories/auth_repository.dart
?? lib/features/auth/presentation/providers/auth_providers.dart
?? lib/features/auth/presentation/view_model/auth_state.dart
?? lib/features/auth/presentation/view_model/auth_view_model.dart
?? lib/features/chat/presentation/view_model/teacher_messages_models.dart
?? lib/features/notifications/data/datasources/local/notifications_local_datasource.dart
?? lib/features/notifications/data/datasources/remote/notifications_remote_datasource.dart
?? lib/features/notifications/data/repositories/notifications_repository_impl.dart
?? lib/features/notifications/domain/repositories/notifications_repository.dart
?? lib/features/notifications/presentation/providers/notifications_provider.dart
?? lib/features/notifications/presentation/view_model/notifications_state.dart
?? lib/features/notifications/presentation/view_model/notifications_view_model.dart
?? lib/features/sensors/presentation/pages/
?? lib/features/sensors/presentation/widgets/emergency_shake_listener.dart
?? lib/features/student_courses/data/datasources/local/student_courses_local_datasource.dart
?? lib/features/student_courses/data/datasources/remote/student_courses_remote_datasource.dart
?? lib/features/student_courses/data/dummy/
?? lib/features/student_courses/data/models/course_model.dart
?? lib/features/student_courses/data/repositories/student_courses_repository_impl.dart
?? lib/features/student_courses/domain/repositories/student_courses_repository.dart
?? lib/features/student_courses/presentation/providers/student_courses_provider.dart
?? lib/features/student_courses/presentation/view_model/course_catalog_state.dart
?? lib/features/student_courses/presentation/view_model/course_catalog_view_model.dart
```

## Git diff name-status
```text
M	.metadata
M	android/app/src/main/AndroidManifest.xml
M	ios/Runner/Info.plist
M	lib/app/app.dart
M	lib/app/routes/app_routes.dart
M	lib/core/api/api_client.dart
M	lib/core/widgets/social_button.dart
M	lib/features/auth/presentation/pages/login_page.dart
M	lib/features/chat/presentation/pages/teacher_messages_page.dart
M	lib/features/notifications/presentation/pages/notifications_page.dart
M	lib/features/onboarding/presentation/pages/onboarding_page.dart
M	lib/features/sensors/presentation/view_model/sensor_state.dart
M	lib/features/sensors/presentation/view_model/sensor_view_model.dart
D	lib/features/student_courses/data/models/dummy_courses.dart
M	lib/features/student_courses/presentation/pages/course_detail_page.dart
M	lib/features/student_courses/presentation/pages/course_page.dart
M	lib/features/student_courses/presentation/pages/course_player_page.dart
M	lib/features/student_courses/presentation/pages/my_courses_page.dart
M	lib/features/student_courses/presentation/pages/search_results_page.dart
M	lib/features/student_courses/presentation/widgets/course_list_item.dart
M	lib/features/student_profile/presentation/pages/settings_privacy_page.dart
M	lib/features/teacher_attendance/presentation/pages/teacher_schedule_session_page.dart
M	lib/features/teacher_courses/presentation/pages/teacher_course_detail_page.dart
M	lib/features/teacher_courses/presentation/pages/teacher_courses_page.dart
M	lib/features/teacher_courses/presentation/pages/teacher_manage_curriculum_page.dart
M	lib/features/teacher_dashboard/presentation/pages/teacher_home_page.dart
M	pubspec.lock
M	pubspec.yaml
M	test/widget/login_page_ui_test.dart
M	test/widget/login_validation_test.dart
```
