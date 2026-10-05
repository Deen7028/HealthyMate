# File Tree: lib

**Generated:** 10/5/2026, 7:35:57 PM
**Root Path:** `/home/kamaruding/modile/flutter/healthymate/lib`

```
├── 📁 core
│   ├── 📁 config
│   │   └── 📄 app_config.dart
│   ├── 📁 database
│   │   ├── 📁 daos
│   │   │   ├── 📄 goal_preference_dao.dart
│   │   │   ├── 📄 goal_preference_dao_devices.dart
│   │   │   ├── 📄 goal_preference_dao_keys.dart
│   │   │   ├── 📄 goal_preference_dao_pending_sync.dart
│   │   │   ├── 📄 goal_preference_dao_sync_records.dart
│   │   │   ├── 📄 health_record_dao.dart
│   │   │   ├── 📄 nutrition_dao.dart
│   │   │   ├── 📄 routine_dao.dart
│   │   │   ├── 📄 routine_dao_history.dart
│   │   │   ├── 📄 routine_dao_logs.dart
│   │   │   ├── 📄 routine_dao_mutations.dart
│   │   │   ├── 📄 user_dao.dart
│   │   │   ├── 📄 user_dao_credentials.dart
│   │   │   ├── 📄 user_dao_registration.dart
│   │   │   ├── 📄 user_dao_session.dart
│   │   │   └── 📄 workout_dao.dart
│   │   ├── 📄 app_database.dart
│   │   ├── 📄 app_database_lifecycle.dart
│   │   └── 📄 app_database_schema.dart
│   ├── 📁 services
│   │   ├── 📄 activity_api_service.dart
│   │   ├── 📄 api_service.dart
│   │   ├── 📄 api_service_config.dart
│   │   ├── 📄 audio_service.dart
│   │   ├── 📄 auth_api_service.dart
│   │   ├── 📄 auth_service.dart
│   │   ├── 📄 biometric_apple_auth_service.dart
│   │   ├── 📄 dashboard_api_service.dart
│   │   ├── 📄 data_export_service.dart
│   │   ├── 📄 email_api_service.dart
│   │   ├── 📄 goal_api_service.dart
│   │   ├── 📄 health_kit_connect_service.dart
│   │   ├── 📄 health_record_api_service.dart
│   │   ├── 📄 location_background_service.dart
│   │   ├── 📄 notification_service.dart
│   │   ├── 📄 notification_service_scheduling.dart
│   │   ├── 📄 onboarding_service.dart
│   │   ├── 📄 profile_api_service.dart
│   │   ├── 📄 routine_api_service.dart
│   │   ├── 📄 routine_state_notifier.dart
│   │   ├── 📄 routine_state_notifier_goal_progress.dart
│   │   ├── 📄 routine_state_notifier_goals.dart
│   │   ├── 📄 routine_state_notifier_loading.dart
│   │   ├── 📄 routine_state_notifier_routines.dart
│   │   ├── 📄 supabase_service.dart
│   │   ├── 📄 sync_service.dart
│   │   ├── 📄 sync_service_downstream.dart
│   │   ├── 📄 sync_service_lifecycle.dart
│   │   ├── 📄 sync_service_sync_activity.dart
│   │   ├── 📄 sync_service_sync_records.dart
│   │   ├── 📄 sync_service_sync_routines.dart
│   │   ├── 📄 sync_service_upstream.dart
│   │   ├── 📄 theme_service.dart
│   │   └── 📄 tts_service.dart
│   ├── 📁 utils
│   │   ├── 📄 health_calculator.dart
│   │   └── 📄 route_utils.dart
│   └── 📄 index.dart
├── 📁 features
│   ├── 📁 auth
│   │   ├── 📁 controllers
│   │   │   └── 📄 forgot_password_controller.dart
│   │   ├── 📁 pages
│   │   │   ├── 📄 forgot_password_page.dart
│   │   │   ├── 📄 forgot_password_page_actions.dart
│   │   │   ├── 📄 forgot_password_page_content.dart
│   │   │   ├── 📄 forgot_password_page_email_form.dart
│   │   │   └── 📄 forgot_password_page_password_form.dart
│   │   ├── 📁 widgets
│   │   │   ├── 📄 index.dart
│   │   │   ├── 📄 otp_verification_dialog.dart
│   │   │   ├── 📄 otp_verification_dialog_actions.dart
│   │   │   └── 📄 otp_verification_dialog_content.dart
│   │   └── 📄 index.dart
│   ├── 📁 dashboard
│   │   ├── 📁 controllers
│   │   │   ├── 📄 dashboard_controller.dart
│   │   │   ├── 📄 dashboard_controller_loading.dart
│   │   │   └── 📄 dashboard_controller_sync.dart
│   │   ├── 📁 models
│   │   │   └── 📄 dashboard_data.dart
│   │   ├── 📁 pages
│   │   │   ├── 📄 dashboard_page.dart
│   │   │   ├── 📄 dashboard_page_actions.dart
│   │   │   └── 📄 dashboard_page_content.dart
│   │   ├── 📁 utils
│   │   │   └── 📄 dashboard_ui_helpers.dart
│   │   ├── 📁 widgets
│   │   │   ├── 📄 activity_progress_ring.dart
│   │   │   ├── 📄 calendar_strip_day_item.dart
│   │   │   ├── 📄 calendar_strip_widget.dart
│   │   │   ├── 📄 daily_routine_checklist.dart
│   │   │   ├── 📄 dashboard_action_buttons.dart
│   │   │   ├── 📄 dashboard_header.dart
│   │   │   ├── 📄 dashboard_health_summary_card.dart
│   │   │   ├── 📄 dashboard_health_summary_card_burn.dart
│   │   │   ├── 📄 dashboard_health_summary_card_layout.dart
│   │   │   ├── 📄 dashboard_health_summary_card_nutrition.dart
│   │   │   ├── 📄 dashboard_health_summary_card_nutrition_energy.dart
│   │   │   ├── 📄 dashboard_health_summary_card_nutrition_header.dart
│   │   │   ├── 📄 dashboard_health_summary_card_nutrition_preview.dart
│   │   │   ├── 📄 dashboard_health_summary_card_personal.dart
│   │   │   ├── 📄 dashboard_health_summary_card_stat_ui.dart
│   │   │   ├── 📄 dashboard_main_goal_card.dart
│   │   │   ├── 📄 dashboard_main_goal_card_helpers.dart
│   │   │   ├── 📄 dashboard_main_goal_card_presentation.dart
│   │   │   ├── 📄 dashboard_main_goal_stats.dart
│   │   │   ├── 📄 dashboard_other_goals_card.dart
│   │   │   ├── 📄 dashboard_other_goals_card_item.dart
│   │   │   ├── 📄 index.dart
│   │   │   ├── 📄 key_stats_grid.dart
│   │   │   ├── 📄 key_stats_grid_cards.dart
│   │   │   ├── 📄 main_goal_card.dart
│   │   │   ├── 📄 main_goal_card_calculations.dart
│   │   │   ├── 📄 main_goal_card_presentation.dart
│   │   │   ├── 📄 main_goal_card_setup_button.dart
│   │   │   ├── 📄 main_goal_card_stat_ui.dart
│   │   │   ├── 📄 main_goal_card_status_footer.dart
│   │   │   └── 📄 start_workout_cta.dart
│   │   └── 📄 index.dart
│   ├── 📁 food_recognition
│   │   ├── 📁 models
│   │   │   └── 📄 food_recognition_models.dart
│   │   ├── 📁 services
│   │   │   ├── 📄 food_recognition_analysis.dart
│   │   │   ├── 📄 food_recognition_gemini.dart
│   │   │   ├── 📄 food_recognition_parsing.dart
│   │   │   ├── 📄 food_recognition_service.dart
│   │   │   └── 📄 food_recognition_values.dart
│   │   ├── 📁 widgets
│   │   │   ├── 📄 burn_it_off_advisor_card.dart
│   │   │   ├── 📄 detected_food_item_card.dart
│   │   │   ├── 📄 edit_food_item_dialog.dart
│   │   │   ├── 📄 edit_food_item_dialog_content.dart
│   │   │   ├── 📄 edit_food_item_dialog_sections.dart
│   │   │   ├── 📄 empty_food_recognition_card.dart
│   │   │   ├── 📄 food_nutrition_summary_card.dart
│   │   │   ├── 📄 food_recognition_result_sheet.dart
│   │   │   ├── 📄 food_recognition_result_sheet_actions.dart
│   │   │   ├── 📄 food_recognition_result_sheet_body.dart
│   │   │   ├── 📄 food_recognition_result_sheet_chrome.dart
│   │   │   ├── 📄 food_recognition_result_sheet_content.dart
│   │   │   ├── 📄 food_recognition_result_sheet_items.dart
│   │   │   ├── 📄 food_recognition_result_sheet_save.dart
│   │   │   ├── 📄 gemini_api_key_dialog.dart
│   │   │   ├── 📄 gemini_api_key_dialog_content.dart
│   │   │   ├── 📄 gemini_api_key_dialog_save.dart
│   │   │   └── 📄 index.dart
│   │   └── 📄 index.dart
│   ├── 📁 health_calculator
│   │   ├── 📁 controllers
│   │   │   ├── 📄 health_calculator_controller.dart
│   │   │   ├── 📄 health_calculator_controller_calculation.dart
│   │   │   ├── 📄 health_calculator_controller_inputs.dart
│   │   │   ├── 📄 health_calculator_controller_loading.dart
│   │   │   └── 📄 health_calculator_controller_persistence.dart
│   │   ├── 📁 models
│   │   │   ├── 📄 activity_level.dart
│   │   │   ├── 📄 calculation_record.dart
│   │   │   ├── 📄 health_record_model.dart
│   │   │   └── 📄 user_model.dart
│   │   ├── 📁 pages
│   │   │   ├── 📄 health_calculator_page.dart
│   │   │   ├── 📄 health_calculator_page_actions.dart
│   │   │   ├── 📄 health_calculator_page_content.dart
│   │   │   └── 📄 health_calculator_page_inputs.dart
│   │   ├── 📁 widgets
│   │   │   ├── 📄 activity_level_picker.dart
│   │   │   ├── 📄 bmi_indicator_bar.dart
│   │   │   ├── 📄 calorie_target_card.dart
│   │   │   ├── 📄 gender_selector.dart
│   │   │   ├── 📄 health_calculator_input_field.dart
│   │   │   ├── 📄 health_calculator_result_content.dart
│   │   │   ├── 📄 health_calculator_result_section.dart
│   │   │   ├── 📄 history_bottom_sheet.dart
│   │   │   ├── 📄 history_bottom_sheet_graph.dart
│   │   │   ├── 📄 history_bottom_sheet_items.dart
│   │   │   ├── 📄 index.dart
│   │   │   ├── 📄 result_card.dart
│   │   │   └── 📄 weight_chart_painter.dart
│   │   └── 📄 index.dart
│   ├── 📁 login
│   │   ├── 📁 pages
│   │   │   ├── 📄 login_page.dart
│   │   │   ├── 📄 login_page_content.dart
│   │   │   ├── 📄 login_page_form_actions.dart
│   │   │   ├── 📄 login_page_google.dart
│   │   │   └── 📄 login_page_other_auth.dart
│   │   ├── 📁 widgets
│   │   │   ├── 📄 index.dart
│   │   │   ├── 📄 login_error_banner.dart
│   │   │   ├── 📄 login_footer_link.dart
│   │   │   ├── 📄 login_form_fields.dart
│   │   │   ├── 📄 login_header.dart
│   │   │   ├── 📄 login_submit_button.dart
│   │   │   └── 📄 social_login_buttons.dart
│   │   └── 📄 index.dart
│   ├── 📁 onboarding
│   │   ├── 📁 models
│   │   │   └── 📄 onboarding_goal_template.dart
│   │   ├── 📁 pages
│   │   │   ├── 📄 onboarding_slides_page.dart
│   │   │   ├── 📄 onboarding_wizard_page.dart
│   │   │   └── 📄 profile_setup_wizard_page.dart
│   │   ├── 📁 widgets
│   │   │   ├── 📄 step1_welcome_view.dart
│   │   │   ├── 📄 step2_body_metrics_view.dart
│   │   │   └── 📄 step3_primary_goal_view.dart
│   │   └── 📄 index.dart
│   ├── 📁 practice
│   │   ├── 📁 controllers
│   │   │   ├── 📄 routine_controller.dart
│   │   │   ├── 📄 routine_controller_create.dart
│   │   │   ├── 📄 routine_controller_goal_sync.dart
│   │   │   ├── 📄 routine_controller_goals.dart
│   │   │   ├── 📄 routine_controller_load.dart
│   │   │   ├── 📄 routine_controller_load_rows.dart
│   │   │   ├── 📄 routine_controller_mutations.dart
│   │   │   ├── 📄 routine_controller_overall_progress.dart
│   │   │   ├── 📄 routine_controller_progress.dart
│   │   │   ├── 📄 routine_controller_sync.dart
│   │   │   ├── 📄 routine_controller_workout_stats.dart
│   │   │   └── 📄 routine_controller_workout_sync.dart
│   │   ├── 📁 models
│   │   │   └── 📄 routine_item.dart
│   │   ├── 📁 pages
│   │   │   ├── 📄 completed_goals_and_routines_page.dart
│   │   │   ├── 📄 completed_goals_empty_state.dart
│   │   │   ├── 📄 completed_goals_history.dart
│   │   │   ├── 📄 completed_goals_page_content.dart
│   │   │   ├── 📄 completed_goals_tab.dart
│   │   │   ├── 📄 completed_routines_tab.dart
│   │   │   ├── 📄 routine_notification_page.dart
│   │   │   ├── 📄 routine_notification_page_actions.dart
│   │   │   ├── 📄 routine_notification_page_card.dart
│   │   │   ├── 📄 routine_notification_page_card_actions.dart
│   │   │   ├── 📄 routine_notification_page_content.dart
│   │   │   ├── 📄 routine_notification_page_dialogs.dart
│   │   │   ├── 📄 routine_notification_page_grouping.dart
│   │   │   └── 📄 routine_notification_page_sections.dart
│   │   ├── 📁 widgets
│   │   │   ├── 📄 add_main_goal_bottom_sheet.dart
│   │   │   ├── 📄 add_main_goal_bottom_sheet_actions.dart
│   │   │   ├── 📄 add_main_goal_bottom_sheet_actions_ui.dart
│   │   │   ├── 📄 add_main_goal_bottom_sheet_sections.dart
│   │   │   ├── 📄 add_routine_dialog.dart
│   │   │   ├── 📄 add_routine_dialog_actions.dart
│   │   │   ├── 📄 add_routine_dialog_content.dart
│   │   │   ├── 📄 add_routine_dialog_steps.dart
│   │   │   ├── 📄 index.dart
│   │   │   ├── 📄 main_goal_template.dart
│   │   │   ├── 📄 progress_summary_card.dart
│   │   │   ├── 📄 routine_card.dart
│   │   │   ├── 📄 routine_card_progress.dart
│   │   │   ├── 📄 routine_card_widget.dart
│   │   │   ├── 📄 routine_countdown_timer_actions.dart
│   │   │   ├── 📄 routine_countdown_timer_content.dart
│   │   │   ├── 📄 routine_countdown_timer_modal.dart
│   │   │   ├── 📄 routine_empty_view.dart
│   │   │   ├── 📄 routine_gps_sync_option.dart
│   │   │   ├── 📄 routine_main_goal_card.dart
│   │   │   ├── 📄 routine_main_goal_card_empty.dart
│   │   │   ├── 📄 routine_main_goal_card_header.dart
│   │   │   ├── 📄 routine_step_category.dart
│   │   │   ├── 📄 routine_step_goal.dart
│   │   │   ├── 📄 routine_step_goal_content.dart
│   │   │   ├── 📄 routine_step_goal_unit_button.dart
│   │   │   ├── 📄 routine_step_style.dart
│   │   │   ├── 📄 routine_step_style_content.dart
│   │   │   ├── 📄 routine_step_style_interval.dart
│   │   │   ├── 📄 routine_step_style_modes.dart
│   │   │   ├── 📄 routine_step_style_multiple_times.dart
│   │   │   ├── 📄 routine_step_style_selectors.dart
│   │   │   ├── 📄 routine_step_style_single_time.dart
│   │   │   ├── 📄 routine_top_overview_banner.dart
│   │   │   └── 📄 routine_top_overview_workout_summary.dart
│   │   └── 📄 index.dart
│   ├── 📁 profile
│   │   ├── 📁 controllers
│   │   │   ├── 📄 profile_controller.dart
│   │   │   ├── 📄 profile_controller_account.dart
│   │   │   ├── 📄 profile_controller_api_key.dart
│   │   │   ├── 📄 profile_controller_devices.dart
│   │   │   ├── 📄 profile_controller_images.dart
│   │   │   ├── 📄 profile_controller_loading.dart
│   │   │   └── 📄 profile_controller_preferences.dart
│   │   ├── 📁 pages
│   │   │   ├── 📄 profile_page.dart
│   │   │   ├── 📄 profile_page_account_actions.dart
│   │   │   ├── 📄 profile_page_content.dart
│   │   │   ├── 📄 profile_page_image_actions.dart
│   │   │   └── 📄 profile_page_sheets.dart
│   │   ├── 📁 widgets
│   │   │   ├── 📄 account_card.dart
│   │   │   ├── 📄 connected_devices_bottom_sheet.dart
│   │   │   ├── 📄 edit_profile_dialog.dart
│   │   │   ├── 📄 edit_profile_dialog_content.dart
│   │   │   ├── 📄 edit_profile_dialog_fields.dart
│   │   │   ├── 📄 edit_profile_dialog_gender.dart
│   │   │   ├── 📄 edit_profile_dialog_header.dart
│   │   │   ├── 📄 edit_profile_dialog_labels.dart
│   │   │   ├── 📄 edit_profile_dialog_save.dart
│   │   │   ├── 📄 index.dart
│   │   │   ├── 📄 logout_confirm_dialog.dart
│   │   │   ├── 📄 personal_info_bottom_sheet.dart
│   │   │   ├── 📄 profile_footer.dart
│   │   │   ├── 📄 profile_header_card.dart
│   │   │   ├── 📄 profile_header_card_goal.dart
│   │   │   ├── 📄 profile_header_card_sections.dart
│   │   │   ├── 📄 profile_top_bar.dart
│   │   │   ├── 📄 quick_stats_card.dart
│   │   │   ├── 📄 settings_card.dart
│   │   │   ├── 📄 settings_card_action_row.dart
│   │   │   └── 📄 unit_picker_bottom_sheet.dart
│   │   └── 📄 index.dart
│   ├── 📁 register
│   │   ├── 📁 controllers
│   │   │   └── 📄 register_controller.dart
│   │   ├── 📁 pages
│   │   │   ├── 📄 register_fade_slide_entrance.dart
│   │   │   ├── 📄 register_page.dart
│   │   │   ├── 📄 register_page_actions.dart
│   │   │   └── 📄 register_page_content.dart
│   │   ├── 📁 utils
│   │   │   └── 📄 password_validator.dart
│   │   ├── 📁 widgets
│   │   │   ├── 📄 index.dart
│   │   │   ├── 📄 password_requirements_card.dart
│   │   │   ├── 📄 register_consent_section.dart
│   │   │   ├── 📄 register_footer_link.dart
│   │   │   ├── 📄 register_form_fields.dart
│   │   │   ├── 📄 register_form_fields_content.dart
│   │   │   ├── 📄 register_header.dart
│   │   │   ├── 📄 register_submit_button.dart
│   │   │   └── 📄 terms_privacy_sheets.dart
│   │   └── 📄 index.dart
│   ├── 📁 workout
│   │   ├── 📁 controllers
│   │   │   ├── 📄 workout_history_controller.dart
│   │   │   ├── 📄 workout_tracking_controller.dart
│   │   │   ├── 📄 workout_tracking_controller_lifecycle.dart
│   │   │   ├── 📄 workout_tracking_controller_location.dart
│   │   │   ├── 📄 workout_tracking_controller_persistence.dart
│   │   │   ├── 📄 workout_tracking_controller_selection.dart
│   │   │   └── 📄 workout_tracking_controller_session.dart
│   │   ├── 📁 models
│   │   │   └── 📄 workout_models.dart
│   │   ├── 📁 pages
│   │   │   ├── 📄 workout_history_page.dart
│   │   │   ├── 📄 workout_share_page.dart
│   │   │   ├── 📄 workout_tracking_page.dart
│   │   │   ├── 📄 workout_tracking_page_actions.dart
│   │   │   ├── 📄 workout_tracking_page_content.dart
│   │   │   └── 📄 workout_tracking_page_location.dart
│   │   ├── 📁 services
│   │   │   ├── 📄 kalman_location_filter.dart
│   │   │   ├── 📄 map_matching_service.dart
│   │   │   └── 📄 workout_recovery_service.dart
│   │   ├── 📁 widgets
│   │   │   ├── 📄 category_selection_view.dart
│   │   │   ├── 📄 history_route_painter.dart
│   │   │   ├── 📄 index.dart
│   │   │   ├── 📄 map_floating_buttons.dart
│   │   │   ├── 📄 mini_route_painter.dart
│   │   │   ├── 📄 workout_bottom_controls.dart
│   │   │   ├── 📄 workout_bottom_controls_action.dart
│   │   │   ├── 📄 workout_dialog_utils.dart
│   │   │   ├── 📄 workout_gps_permission_dialog.dart
│   │   │   ├── 📄 workout_history_card_sections.dart
│   │   │   ├── 📄 workout_history_empty_card.dart
│   │   │   ├── 📄 workout_history_item_card.dart
│   │   │   ├── 📄 workout_map_type_selector.dart
│   │   │   ├── 📄 workout_map_view.dart
│   │   │   ├── 📄 workout_share_actions.dart
│   │   │   ├── 📄 workout_share_card.dart
│   │   │   ├── 📄 workout_stop_action_sheet.dart
│   │   │   ├── 📄 workout_top_stats_card.dart
│   │   │   ├── 📄 workout_top_stats_card_header.dart
│   │   │   └── 📄 zen_focus_background.dart
│   │   └── 📄 index.dart
│   └── 📄 index.dart
├── 📁 shared
│   ├── 📁 bottom_sheets
│   │   ├── 📄 food_source_bottom_sheet.dart
│   │   └── 📄 food_source_bottom_sheet_option.dart
│   ├── 📁 theme
│   │   ├── 📄 app_theme.dart
│   │   ├── 📄 index.dart
│   │   └── 📄 theme_service.dart
│   ├── 📁 widgets
│   │   ├── 📄 fade_slide_entrance.dart
│   │   ├── 📄 sync_status_badge.dart
│   │   ├── 📄 vitality_bottom_nav_bar.dart
│   │   └── 📄 vitality_bottom_nav_bar_item.dart
│   └── 📄 index.dart
├── 📄 main.dart
└── 📄 main_app.dart
```

---
*Generated by FileTree Pro Extension*