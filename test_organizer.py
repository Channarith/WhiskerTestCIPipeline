#!/usr/bin/env python3
"""
Whisker Test Organizer
Creates organized, categorized test suites for different app features
"""

import os
from datetime import datetime

class TestOrganizer:
    def __init__(self, app_id="com.whisker.android"):
        self.app_id = app_id
        self.test_categories = {
            'profile': 'Profile & Account Tests',
            'pets': 'Pet Management Tests',
            'devices': 'Device Management Tests',
            'shop': 'Shop & Commerce Tests',
            'insights': 'Insights & Analytics Tests',
            'settings': 'Settings & Support Tests',
            'navigation': 'Navigation & UI Tests',
            'onboarding': 'Onboarding & Registration Tests'
        }
        self.tests_dir = "tests/organized"
        os.makedirs(self.tests_dir, exist_ok=True)
    
    def get_home_and_logout(self):
        """
        Return proper Home and Logout flow
        This should be at the end of EVERY test
        """
        return """
# ============================================================
# CLEANUP - Return Home & Logout
# ============================================================

# Return to home
- tapOn: "Home\\nTab 1 of 5"
- waitForAnimationToEnd
- takeScreenshot: "99_back_to_home"

# Logout
- runFlow:
    when:
      visible: "Devices"
    commands:
      - tapOn: 
          point: "92%,5%"
      - waitForAnimationToEnd
      - tapOn:
          point: "50%,15%"
      - waitForAnimationToEnd
      - tapOn: "Log Out"
      - waitForAnimationToEnd
      - assertVisible: "Are you sure you want to Log Out?"
      - tapOn: "Yes, Log Me Out"
      - waitForAnimationToEnd
      - assertVisible: "Login|Sign In"
      - takeScreenshot: "99_logged_out"
"""
    
    def get_clean_state_init(self):
        """
        Return initialization steps that ensure clean app state and login
        This should be at the beginning of EVERY test
        """
        return f"""# ============================================================
# INITIALIZATION - Clean State & Automatic Login
# ============================================================
# Ensures consistent starting point: clear state, launch app, auto-login

- clearState: {self.app_id}
- launchApp: {self.app_id}
- waitForAnimationToEnd
- takeScreenshot: "00_app_launched"

# Handle onboarding/welcome screens (if first launch)
- runFlow:
    when:
      visible: "Get Started|Start|Begin|Welcome"
    commands:
      - tapOn: "Get Started"
      - waitForAnimationToEnd
      - takeScreenshot: "00a_onboarding_skipped"

# Navigate to Login if we see Login/Register screen
- runFlow:
    when:
      visible: "Login|Sign In"
    commands:
      - tapOn: "Login"
      - waitForAnimationToEnd
      - takeScreenshot: "00b_login_screen"

# Perform automatic login if login screen is visible
- runFlow:
    when:
      visible: "Email|Username"
    commands:
      - tapOn: "Email"
      - inputText: "test_h954605d@whiskertest.com"
      - hideKeyboard
      - waitForAnimationToEnd
      
      - tapOn: "Password"
      - inputText: "6uS3%FQqx5n&"
      - hideKeyboard
      - waitForAnimationToEnd
      
      - tapOn: "Login"
      - waitForAnimationToEnd
      - takeScreenshot: "00c_login_submitted"
      
      # Handle Google Password Manager (tap "Not now" / deny)
      - runFlow:
          when:
            visible: "Save|Not now"
          commands:
            - runFlow:
                when:
                  visible:
                    id: com.android.permissioncontroller:id/permission_deny_button
                commands:
                  - tapOn:
                      id: com.android.permissioncontroller:id/permission_deny_button
                  - waitForAnimationToEnd

# Handle notification permission popup (tap "Allow")
- runFlow:
    when:
      visible:
        id: com.android.permissioncontroller:id/permission_allow_button
    commands:
      - tapOn:
          id: com.android.permissioncontroller:id/permission_allow_button
      - waitForAnimationToEnd
      - takeScreenshot: "00d_notifications_allowed"

# Wait for home screen to fully load
- waitForAnimationToEnd
- takeScreenshot: "00e_ready_home_screen"

"""
    
    def create_profile_tests(self):
        """Create comprehensive profile and account tests"""
        test_content = f"""appId: {self.app_id}
---
# PROFILE & ACCOUNT MANAGEMENT TESTS
# Generated: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}
# Tests: Profile info, Login info, Addresses, Payment methods, Settings

{self.get_clean_state_init()}
# ============================================================
# START OF ACTUAL TEST
# ============================================================

- takeScreenshot: "profile_00_home_start"

# ============================================================
# TEST 1: Access Profile from Home
# ============================================================
- tapOn:
    point: "92%,5%"
- waitForAnimationToEnd
- takeScreenshot: "profile_01_menu_opened"

# ============================================================
# TEST 2: Navigate to Login Information
# ============================================================
- tapOn: "Login Information"
- waitForAnimationToEnd
- takeScreenshot: "profile_02_login_info"

# Explore login information page
- scroll
- waitForAnimationToEnd
- takeScreenshot: "profile_03_login_info_scrolled"

# ============================================================
# TEST 3: Check Reset Password
# ============================================================
- tapOn: "Reset Password"
- waitForAnimationToEnd
- takeScreenshot: "profile_04_reset_password"
- tapOn: "Back"
- waitForAnimationToEnd

# Go back to profile menu
- back
- waitForAnimationToEnd
- takeScreenshot: "profile_05_back_to_menu"

# ============================================================
# TEST 4: Navigate to Addresses
# ============================================================
- runFlow:
    when:
      visible: "Addresses|Address"
    commands:
      - tapOn: "Addresses"
      - waitForAnimationToEnd
      - takeScreenshot: "profile_06_addresses"
      - scroll
      - takeScreenshot: "profile_06b_addresses_scrolled"
      - back
      - waitForAnimationToEnd

# ============================================================
# TEST 5: Navigate to Payment Methods
# ============================================================
- runFlow:
    when:
      visible: "Payment|Payment Methods"
    commands:
      - tapOn: "Payment"
      - waitForAnimationToEnd
      - takeScreenshot: "profile_07_payment_methods"
      - scroll
      - takeScreenshot: "profile_07b_payment_scrolled"
      - back
      - waitForAnimationToEnd

# ============================================================
# TEST 6: Scroll through all profile options
# ============================================================
- scroll
- waitForAnimationToEnd
- takeScreenshot: "profile_08_scroll_1"

- scroll
- waitForAnimationToEnd
- takeScreenshot: "profile_09_scroll_2"

- scroll
- waitForAnimationToEnd
- takeScreenshot: "profile_10_scroll_3"

# ============================================================
# TEST 7: Check Settings
# ============================================================
- runFlow:
    when:
      visible: "Settings|Preferences"
    commands:
      - tapOn: "Settings"
      - waitForAnimationToEnd
      - takeScreenshot: "profile_11_settings"
      - scroll
      - takeScreenshot: "profile_11b_settings_scrolled"
      - back
      - waitForAnimationToEnd

# ============================================================
# TEST 8: Check Support/Help
# ============================================================
- runFlow:
    when:
      visible: "Support|Help|Contact"
    commands:
      - tapOn: "Support"
      - waitForAnimationToEnd
      - takeScreenshot: "profile_12_support"
      - scroll
      - takeScreenshot: "profile_12b_support_scrolled"
      - back
      - waitForAnimationToEnd

{self.get_home_and_logout()}
"""
        filename = f"{self.tests_dir}/01_profile_account_tests.yaml"
        with open(filename, 'w') as f:
            f.write(test_content)
        print(f"✅ Created: {filename}")
        return filename
    
    def create_pets_tests(self):
        """Create comprehensive pet management tests"""
        test_content = f"""appId: {self.app_id}
---
# PET MANAGEMENT TESTS
# Generated: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}
# Tests: Add Dog, Add Cat, Pet profiles, Pet settings

{self.get_clean_state_init()}
# ============================================================
# START OF ACTUAL TEST
# ============================================================

- takeScreenshot: "pets_00_home_start"

# ============================================================
# TEST 1: Navigate to Pets Tab
# ============================================================
- tapOn: "Pets\\nTab 4 of 5"
- waitForAnimationToEnd
- takeScreenshot: "pets_01_tab_opened"

# ============================================================
# TEST 2: Create Pet Profile (Dog)
# ============================================================
- tapOn: "Create a Pet Profile"
- waitForAnimationToEnd
- takeScreenshot: "pets_02_create_profile_screen"

# Select Dog
- runFlow:
    when:
      visible: "Dog|dog"
    commands:
      - tapOn: "Dog"
      - waitForAnimationToEnd
      - takeScreenshot: "pets_03_dog_selected"

# Enter pet details
- runFlow:
    when:
      visible: "Pet Name|Name"
    commands:
      - tapOn: "Pet Name"
      - inputText: "TestDog"
      - hideKeyboard
      - takeScreenshot: "pets_04_dog_name_entered"

# Scroll and continue with dog setup
- scroll
- waitForAnimationToEnd
- takeScreenshot: "pets_05_dog_form_scrolled"

# Select breed (if available)
- runFlow:
    when:
      visible: "Breed|Select Breed"
    commands:
      - tapOn: "Breed"
      - waitForAnimationToEnd
      - takeScreenshot: "pets_06_breed_selector"
      # Select first breed option
      - tapOn:
          point: "50%,30%"
      - waitForAnimationToEnd

# Continue or Save
- runFlow:
    when:
      visible: "Continue|Next|Save"
    commands:
      - tapOn: "Continue"
      - waitForAnimationToEnd
      - takeScreenshot: "pets_07_dog_created"

# Go through any additional setup screens
- waitForAnimationToEnd
- takeScreenshot: "pets_08_dog_setup_complete"

# Return to pets list
- runFlow:
    when:
      visible: "Back|Done|Finish"
    commands:
      - tapOn: "Back"
      - waitForAnimationToEnd

# ============================================================
# TEST 3: Create Pet Profile (Cat)
# ============================================================
- runFlow:
    when:
      visible: "Add|Create a Pet Profile|\\+"
    commands:
      - tapOn: "Create a Pet Profile"
      - waitForAnimationToEnd
      - takeScreenshot: "pets_09_create_cat_screen"

# Select Cat
- runFlow:
    when:
      visible: "Cat|cat"
    commands:
      - tapOn: "Cat"
      - waitForAnimationToEnd
      - takeScreenshot: "pets_10_cat_selected"

# Enter cat details
- runFlow:
    when:
      visible: "Pet Name|Name"
    commands:
      - tapOn: "Pet Name"
      - inputText: "TestCat"
      - hideKeyboard
      - takeScreenshot: "pets_11_cat_name_entered"

# Scroll and continue with cat setup
- scroll
- waitForAnimationToEnd
- takeScreenshot: "pets_12_cat_form_scrolled"

# Continue or Save
- runFlow:
    when:
      visible: "Continue|Next|Save"
    commands:
      - tapOn: "Continue"
      - waitForAnimationToEnd
      - takeScreenshot: "pets_13_cat_created"

# ============================================================
# TEST 4: Explore Pet Options
# ============================================================
- waitForAnimationToEnd
- takeScreenshot: "pets_14_pets_list"

# Tap on first pet
- runFlow:
    when:
      visible: "TestDog|TestCat"
    commands:
      - tapOn:
          point: "50%,40%"
      - waitForAnimationToEnd
      - takeScreenshot: "pets_15_pet_details"
      - scroll
      - takeScreenshot: "pets_16_pet_details_scrolled"
      - back
      - waitForAnimationToEnd

{self.get_home_and_logout()}
"""
        filename = f"{self.tests_dir}/02_pet_management_tests.yaml"
        with open(filename, 'w') as f:
            f.write(test_content)
        print(f"✅ Created: {filename}")
        return filename
    
    def create_shop_tests(self):
        """Create comprehensive shop and commerce tests"""
        test_content = f"""appId: {self.app_id}
---
# SHOP & COMMERCE TESTS
# Generated: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}
# Tests: Shop navigation, Accept cookies, Browse products, Categories

{self.get_clean_state_init()}
# ============================================================
# START OF ACTUAL TEST
# ============================================================

- takeScreenshot: "shop_00_home_start"

# ============================================================
# TEST 1: Navigate to Shop Tab
# ============================================================
- tapOn: "Shop\\nTab 5 of 5"
- waitForAnimationToEnd
- takeScreenshot: "shop_01_tab_opened"

# ============================================================
# TEST 2: Handle Cookie Consent
# ============================================================
- runFlow:
    when:
      visible: "Accept|Accept Cookies|Accept All|OK"
    commands:
      - takeScreenshot: "shop_02_cookie_banner"
      - tapOn: "Accept"
      - waitForAnimationToEnd
      - takeScreenshot: "shop_03_cookies_accepted"

# ============================================================
# TEST 3: Browse Shop Home
# ============================================================
- scroll
- waitForAnimationToEnd
- takeScreenshot: "shop_04_scroll_1"

- scroll
- waitForAnimationToEnd
- takeScreenshot: "shop_05_scroll_2"

- scroll
- waitForAnimationToEnd
- takeScreenshot: "shop_06_scroll_3"

# Scroll back up
- swipe:
    direction: UP
- waitForAnimationToEnd
- takeScreenshot: "shop_07_back_to_top"

# ============================================================
# TEST 4: Explore Categories
# ============================================================
- runFlow:
    when:
      visible: "Categories|Category|Browse"
    commands:
      - tapOn: "Categories"
      - waitForAnimationToEnd
      - takeScreenshot: "shop_08_categories"
      - scroll
      - takeScreenshot: "shop_09_categories_scrolled"
      - back
      - waitForAnimationToEnd

# ============================================================
# TEST 5: View Product Details
# ============================================================
# Tap on first visible product
- tapOn:
    point: "50%,40%"
- waitForAnimationToEnd
- takeScreenshot: "shop_10_product_details"

# Scroll through product details
- scroll
- waitForAnimationToEnd
- takeScreenshot: "shop_11_product_details_scrolled"

# Check product images/reviews
- scroll
- waitForAnimationToEnd
- takeScreenshot: "shop_12_product_more_info"

# Go back to shop
- back
- waitForAnimationToEnd
- takeScreenshot: "shop_13_back_to_shop"

# ============================================================
# TEST 6: Check Shopping Cart
# ============================================================
- runFlow:
    when:
      visible: "Cart|🛒|Basket"
    commands:
      - tapOn: "Cart"
      - waitForAnimationToEnd
      - takeScreenshot: "shop_14_cart"
      - back
      - waitForAnimationToEnd

# ============================================================
# TEST 7: Search Products
# ============================================================
- runFlow:
    when:
      visible: "Search|🔍"
    commands:
      - tapOn: "Search"
      - waitForAnimationToEnd
      - inputText: "litter"
      - waitForAnimationToEnd
      - takeScreenshot: "shop_15_search_results"
      - hideKeyboard
      - back
      - waitForAnimationToEnd

{self.get_home_and_logout()}
"""
        filename = f"{self.tests_dir}/03_shop_commerce_tests.yaml"
        with open(filename, 'w') as f:
            f.write(test_content)
        print(f"✅ Created: {filename}")
        return filename
    
    def create_devices_tests(self):
        """Create exhaustive device exploration tests"""
        test_content = f"""appId: {self.app_id}
---
# DEVICE MANAGEMENT TESTS - EXHAUSTIVE
# Generated: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}
# Tests: Litter-Robot, LitterHopper, Feeder-Robot setup
# Strategy: Click everything until no more options available

{self.get_clean_state_init()}
# ============================================================
# START OF ACTUAL TEST
# ============================================================

- takeScreenshot: "devices_00_home_start"

# ============================================================
# TEST 1: Navigate to Devices Tab
# ============================================================
- tapOn: "Devices\\nTab 3 of 5"
- waitForAnimationToEnd
- takeScreenshot: "devices_01_tab_opened"

# ============================================================
# TEST 2: Explore Litter-Robot Setup
# ============================================================
- tapOn: "Add a Device"
- waitForAnimationToEnd
- takeScreenshot: "devices_02_add_device_screen"

# Look for Litter-Robot option
- runFlow:
    when:
      visible: "Litter-Robot|Litter Robot"
    commands:
      - takeScreenshot: "devices_03_litter_robot_option"
      - tapOn: "Litter-Robot"
      - waitForAnimationToEnd
      - takeScreenshot: "devices_04_litter_robot_selected"
      
      # Go through setup screens
      - runFlow:
          when:
            visible: "Continue|Next|Get Started"
          commands:
            - tapOn: "Continue"
            - waitForAnimationToEnd
            - takeScreenshot: "devices_05_lr_step1"
      
      # Screen 2
      - runFlow:
          when:
            visible: "Continue|Next"
          commands:
            - tapOn: "Continue"
            - waitForAnimationToEnd
            - takeScreenshot: "devices_06_lr_step2"
      
      # Screen 3 - WiFi setup
      - runFlow:
          when:
            visible: "Continue|Next|Connect"
          commands:
            - tapOn: "Continue"
            - waitForAnimationToEnd
            - takeScreenshot: "devices_07_lr_wifi"
      
      # Screen 4 - Pairing
      - runFlow:
          when:
            visible: "Continue|Next|Pair"
          commands:
            - tapOn: "Continue"
            - waitForAnimationToEnd
            - takeScreenshot: "devices_08_lr_pairing"
      
      # Screen 5 - Model selection
      - runFlow:
          when:
            visible: "Continue|Next|Select"
          commands:
            - scroll
            - takeScreenshot: "devices_09_lr_model_options"
            - tapOn:
                point: "50%,40%"
            - waitForAnimationToEnd
            - takeScreenshot: "devices_10_lr_model_selected"
            - tapOn: "Continue"
            - waitForAnimationToEnd
      
      # Final steps
      - scroll
      - takeScreenshot: "devices_11_lr_final_setup"
      
      # Exit setup
      - back
      - back

# ============================================================
# TEST 3: Explore Feeder-Robot Setup
# ============================================================
- tapOn: "Add a Device"
- waitForAnimationToEnd

- runFlow:
    when:
      visible: "Feeder-Robot|Feeder Robot"
    commands:
      - takeScreenshot: "devices_12_feeder_robot_option"
      - tapOn: "Feeder-Robot"
      - waitForAnimationToEnd
      - takeScreenshot: "devices_13_feeder_robot_selected"
      
      # Setup flow for Feeder-Robot
      - runFlow:
          when:
            visible: "Continue|Next|Get Started"
          commands:
            - tapOn: "Continue"
            - waitForAnimationToEnd
            - takeScreenshot: "devices_14_fr_step1"
      
      - runFlow:
          when:
            visible: "Continue|Next"
          commands:
            - tapOn: "Continue"
            - waitForAnimationToEnd
            - takeScreenshot: "devices_15_fr_step2"
      
      - runFlow:
          when:
            visible: "Continue|Next|Connect"
          commands:
            - tapOn: "Continue"
            - waitForAnimationToEnd
            - takeScreenshot: "devices_16_fr_wifi"
      
      - runFlow:
          when:
            visible: "Continue|Next"
          commands:
            - scroll
            - takeScreenshot: "devices_17_fr_options"
            - tapOn: "Continue"
            - waitForAnimationToEnd
            - takeScreenshot: "devices_18_fr_complete"
      
      # Exit
      - back
      - back

# ============================================================
# TEST 4: Explore LitterHopper Setup
# ============================================================
- tapOn: "Add a Device"
- waitForAnimationToEnd

- runFlow:
    when:
      visible: "LitterHopper|Litter Hopper"
    commands:
      - takeScreenshot: "devices_19_litterhopper_option"
      - tapOn: "LitterHopper"
      - waitForAnimationToEnd
      - takeScreenshot: "devices_20_litterhopper_selected"
      
      # Setup flow
      - runFlow:
          when:
            visible: "Continue|Next|Get Started"
          commands:
            - tapOn: "Continue"
            - waitForAnimationToEnd
            - takeScreenshot: "devices_21_lh_step1"
      
      - runFlow:
          when:
            visible: "Continue|Next"
          commands:
            - tapOn: "Continue"
            - waitForAnimationToEnd
            - takeScreenshot: "devices_22_lh_step2"
      
      - scroll
      - takeScreenshot: "devices_23_lh_options"
      
      - runFlow:
          when:
            visible: "Continue|Next|Finish"
          commands:
            - tapOn: "Continue"
            - waitForAnimationToEnd
            - takeScreenshot: "devices_24_lh_complete"
      
      # Exit
      - back
      - back

# ============================================================
# TEST 5: Explore All Device Options on Main Screen
# ============================================================
- takeScreenshot: "devices_25_main_screen"

# Scroll through all options
- scroll
- waitForAnimationToEnd
- takeScreenshot: "devices_26_scroll_1"

- scroll
- waitForAnimationToEnd
- takeScreenshot: "devices_27_scroll_2"

- scroll
- waitForAnimationToEnd
- takeScreenshot: "devices_28_scroll_3"

# Try tapping on any device cards if they exist
- runFlow:
    when:
      visible: "Robot|Device"
    commands:
      - tapOn:
          point: "50%,50%"
      - waitForAnimationToEnd
      - takeScreenshot: "devices_29_device_details"
      - scroll
      - takeScreenshot: "devices_30_device_details_scrolled"
      - back
      - waitForAnimationToEnd

# ============================================================
# TEST 6: Check Device Settings/Options
# ============================================================
- runFlow:
    when:
      visible: "Settings|Options|⚙"
    commands:
      - tapOn: "Settings"
      - waitForAnimationToEnd
      - takeScreenshot: "devices_31_settings"
      - scroll
      - takeScreenshot: "devices_32_settings_scrolled"
      - back
      - waitForAnimationToEnd

{self.get_home_and_logout()}
"""
        filename = f"{self.tests_dir}/04_device_management_tests.yaml"
        with open(filename, 'w') as f:
            f.write(test_content)
        print(f"✅ Created: {filename}")
        return filename
    
    def create_insights_tests(self):
        """Create exhaustive insights and analytics tests"""
        test_content = f"""appId: {self.app_id}
---
# INSIGHTS & ANALYTICS TESTS - EXHAUSTIVE
# Generated: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}
# Tests: Activity graphs, Health metrics, Analytics, Export data

{self.get_clean_state_init()}
# ============================================================
# START OF ACTUAL TEST
# ============================================================

- takeScreenshot: "insights_00_home_start"

# ============================================================
# TEST 1: Navigate to Insights Tab
# ============================================================
- tapOn: "Insights\\nTab 2 of 5"
- waitForAnimationToEnd
- takeScreenshot: "insights_01_tab_opened"

# ============================================================
# TEST 2: Explore Main Dashboard
# ============================================================
# Scroll to see all widgets
- scroll
- waitForAnimationToEnd
- takeScreenshot: "insights_02_scroll_1"

- scroll
- waitForAnimationToEnd
- takeScreenshot: "insights_03_scroll_2"

- scroll
- waitForAnimationToEnd
- takeScreenshot: "insights_04_scroll_3"

# Scroll back to top
- swipe:
    direction: UP
- waitForAnimationToEnd
- takeScreenshot: "insights_05_back_to_top"

# ============================================================
# TEST 3: Explore Activity Graphs
# ============================================================
- runFlow:
    when:
      visible: "Activity|Activities|Usage"
    commands:
      - tapOn: "Activity"
      - waitForAnimationToEnd
      - takeScreenshot: "insights_06_activity_graph"
      
      # Try different time periods
      - runFlow:
          when:
            visible: "Day|Week|Month|Year"
          commands:
            - tapOn: "Week"
            - waitForAnimationToEnd
            - takeScreenshot: "insights_07_activity_week"
            
            - tapOn: "Month"
            - waitForAnimationToEnd
            - takeScreenshot: "insights_08_activity_month"
      
      - scroll
      - takeScreenshot: "insights_09_activity_scrolled"
      
      - back
      - waitForAnimationToEnd

# ============================================================
# TEST 4: Explore Health Metrics
# ============================================================
- runFlow:
    when:
      visible: "Health|Wellness|Metrics"
    commands:
      - tapOn: "Health"
      - waitForAnimationToEnd
      - takeScreenshot: "insights_10_health_metrics"
      
      - scroll
      - takeScreenshot: "insights_11_health_scrolled"
      
      # Explore individual metrics
      - runFlow:
          when:
            visible: "Weight|Bathroom"
          commands:
            - tapOn:
                point: "50%,40%"
            - waitForAnimationToEnd
            - takeScreenshot: "insights_12_metric_details"
            - back
            - waitForAnimationToEnd
      
      - back
      - waitForAnimationToEnd

# ============================================================
# TEST 5: Check Analytics/Stats
# ============================================================
- runFlow:
    when:
      visible: "Analytics|Statistics|Stats"
    commands:
      - tapOn: "Analytics"
      - waitForAnimationToEnd
      - takeScreenshot: "insights_13_analytics"
      
      - scroll
      - takeScreenshot: "insights_14_analytics_scrolled"
      
      - back
      - waitForAnimationToEnd

# ============================================================
# TEST 6: Explore Reports
# ============================================================
- runFlow:
    when:
      visible: "Reports|Report"
    commands:
      - tapOn: "Reports"
      - waitForAnimationToEnd
      - takeScreenshot: "insights_15_reports"
      
      - scroll
      - takeScreenshot: "insights_16_reports_scrolled"
      
      # Try to access a report
      - runFlow:
          when:
            visible: "View|Open|Download"
          commands:
            - tapOn: "View"
            - waitForAnimationToEnd
            - takeScreenshot: "insights_17_report_details"
            - back
            - waitForAnimationToEnd
      
      - back
      - waitForAnimationToEnd

# ============================================================
# TEST 7: Explore Data Export Options
# ============================================================
- runFlow:
    when:
      visible: "Export|Download|Share"
    commands:
      - tapOn: "Export"
      - waitForAnimationToEnd
      - takeScreenshot: "insights_18_export_options"
      
      - scroll
      - takeScreenshot: "insights_19_export_scrolled"
      
      - back
      - waitForAnimationToEnd

# ============================================================
# TEST 8: Check Pet-Specific Insights
# ============================================================
- runFlow:
    when:
      visible: "Pet|Select Pet"
    commands:
      - tapOn: "Pet"
      - waitForAnimationToEnd
      - takeScreenshot: "insights_20_pet_selector"
      
      # Select first pet
      - tapOn:
          point: "50%,35%"
      - waitForAnimationToEnd
      - takeScreenshot: "insights_21_pet_selected"

# ============================================================
# TEST 9: Explore Timeline/History
# ============================================================
- runFlow:
    when:
      visible: "Timeline|History"
    commands:
      - tapOn: "Timeline"
      - waitForAnimationToEnd
      - takeScreenshot: "insights_22_timeline"
      
      - scroll
      - takeScreenshot: "insights_23_timeline_scrolled"
      
      - scroll
      - takeScreenshot: "insights_24_timeline_more"
      
      - back
      - waitForAnimationToEnd

# ============================================================
# TEST 10: Check Settings/Filters
# ============================================================
- runFlow:
    when:
      visible: "Filter|Settings|⚙"
    commands:
      - tapOn: "Filter"
      - waitForAnimationToEnd
      - takeScreenshot: "insights_25_filters"
      
      - scroll
      - takeScreenshot: "insights_26_filters_scrolled"
      
      - back
      - waitForAnimationToEnd

# ============================================================
# TEST 11: Explore Notifications/Alerts
# ============================================================
- runFlow:
    when:
      visible: "Notifications|Alerts|🔔"
    commands:
      - tapOn: "Notifications"
      - waitForAnimationToEnd
      - takeScreenshot: "insights_27_notifications"
      
      - scroll
      - takeScreenshot: "insights_28_notifications_scrolled"
      
      - back
      - waitForAnimationToEnd

# ============================================================
# TEST 12: Tap on Various Charts/Graphs
# ============================================================
# Try tapping on different sections of the insights screen
- tapOn:
    point: "30%,40%"
- waitForAnimationToEnd
- takeScreenshot: "insights_29_tap_area_1"
- runFlow:
    when:
      visible: "Close|Back|X"
    commands:
      - back
      - waitForAnimationToEnd

- tapOn:
    point: "70%,40%"
- waitForAnimationToEnd
- takeScreenshot: "insights_30_tap_area_2"
- runFlow:
    when:
      visible: "Close|Back|X"
    commands:
      - back
      - waitForAnimationToEnd

- tapOn:
    point: "50%,60%"
- waitForAnimationToEnd
- takeScreenshot: "insights_31_tap_area_3"
- runFlow:
    when:
      visible: "Close|Back|X"
    commands:
      - back
      - waitForAnimationToEnd

# ============================================================
# TEST 13: Final Full Scroll Exploration
# ============================================================
- takeScreenshot: "insights_32_final_view"

- scroll
- waitForAnimationToEnd
- takeScreenshot: "insights_33_final_scroll_1"

- scroll
- waitForAnimationToEnd
- takeScreenshot: "insights_34_final_scroll_2"

- scroll
- waitForAnimationToEnd
- takeScreenshot: "insights_35_final_scroll_3"

{self.get_home_and_logout()}
"""
        filename = f"{self.tests_dir}/05_insights_analytics_tests.yaml"
        with open(filename, 'w') as f:
            f.write(test_content)
        print(f"✅ Created: {filename}")
        return filename
    
    def create_logout_login_tests(self):
        """Create logout and fresh login tests"""
        test_content = f"""appId: {self.app_id}
---
# LOGOUT & FRESH LOGIN TESTS
# Generated: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}
# Tests: Complete logout flow, Fresh login with saved credentials

{self.get_clean_state_init()}
# ============================================================
# START OF ACTUAL TEST
# ============================================================

- takeScreenshot: "logout_00_start"

# ============================================================
# TEST 1: Navigate to Profile
# ============================================================
- tapOn:
    point: "92%,5%"
- waitForAnimationToEnd
- takeScreenshot: "logout_01_profile_menu"

# ============================================================
# TEST 2: Click on Person's Name/Email (with ">")
# ============================================================
# This should be the top option with name, email, and ">" symbol
- tapOn:
    point: "50%,15%"
- waitForAnimationToEnd
- takeScreenshot: "logout_02_account_details"

# Scroll to see logout button
- scroll
- waitForAnimationToEnd
- takeScreenshot: "logout_03_scrolled"

- scroll
- waitForAnimationToEnd
- takeScreenshot: "logout_04_scrolled_more"

# ============================================================
# TEST 3: Tap Orange "Log Out" Button
# ============================================================
- runFlow:
    when:
      visible: "Log Out|Logout|LOGOUT"
    commands:
      - takeScreenshot: "logout_05_found_logout_button"
      - tapOn: "Log Out"
      - waitForAnimationToEnd
      - takeScreenshot: "logout_06_logout_clicked"

# Handle confirmation if any
- runFlow:
    when:
      visible: "Confirm|Yes|OK|Log Out"
    commands:
      - takeScreenshot: "logout_07_confirmation"
      - tapOn: "Log Out"
      - waitForAnimationToEnd

# ============================================================
# TEST 4: Verify Logged Out State
# ============================================================
- waitForAnimationToEnd
- takeScreenshot: "logout_08_logged_out"

# Should see login/register screen
- assertVisible: "Login|Sign In|Register"
- takeScreenshot: "logout_09_login_screen_visible"

# ============================================================
# TEST 5: Fresh Login with Saved Credentials
# ============================================================
# Navigate to Login
- runFlow:
    when:
      visible: "Login|Sign In"
    commands:
      - tapOn: "Login"
      - waitForAnimationToEnd
      - takeScreenshot: "login_01_login_screen"

# Wait for login form
- waitForAnimationToEnd
- takeScreenshot: "login_02_ready_for_input"

# Enter Email (using last saved credential from test_credentials.json)
# Note: Replace with actual email from saved credentials
- runFlow:
    when:
      visible: "Email|Username"
    commands:
      - tapOn: "Email"
      - inputText: "{{SAVED_EMAIL}}"
      - hideKeyboard
      - takeScreenshot: "login_03_email_entered"

# Enter Password
- runFlow:
    when:
      visible: "Password"
    commands:
      - tapOn: "Password"
      - inputText: "{{SAVED_PASSWORD}}"
      - hideKeyboard
      - takeScreenshot: "login_04_password_entered"

# Click Login Button
- runFlow:
    when:
      visible: "Login|Sign In|Continue"
    commands:
      - tapOn: "Login"
      - waitForAnimationToEnd
      - takeScreenshot: "login_05_login_clicked"

# ============================================================
# TEST 6: Handle Post-Login Screens
# ============================================================
# Google Password Manager popup
- runFlow:
    when:
      visible: "Save|Not now|Never"
    commands:
      - takeScreenshot: "login_06_password_manager"
      - tapOn:
          id: com.android.permissioncontroller:id/permission_deny_button
      - waitForAnimationToEnd

# Any welcome back screens
- runFlow:
    when:
      visible: "Welcome Back|Continue"
    commands:
      - tapOn: "Continue"
      - waitForAnimationToEnd

# ============================================================
# TEST 7: Verify Successful Login
# ============================================================
- waitForAnimationToEnd
- takeScreenshot: "login_07_logged_in_home"

# Verify we're on home screen
- assertVisible: "Home"
- takeScreenshot: "login_08_verify_home"

# Verify profile accessible
- tapOn:
    point: "92%,5%"
- waitForAnimationToEnd
- takeScreenshot: "login_09_profile_accessible"
- back
- waitForAnimationToEnd

{self.get_home_and_logout()}
"""
        filename = f"{self.tests_dir}/06_logout_login_tests.yaml"
        with open(filename, 'w') as f:
            f.write(test_content)
        print(f"✅ Created: {filename}")
        return filename
    
    def create_all_tests(self):
        """Generate all organized test files"""
        print("\n🎯 Creating Organized Test Suite")
        print("=" * 60)
        
        tests_created = []
        
        # Create each test category
        tests_created.append(self.create_profile_tests())
        tests_created.append(self.create_pets_tests())
        tests_created.append(self.create_shop_tests())
        tests_created.append(self.create_devices_tests())
        tests_created.append(self.create_insights_tests())
        tests_created.append(self.create_logout_login_tests())
        
        # Calculate estimated time
        print("\n" + "=" * 60)
        print(f"✅ Created {len(tests_created)} test suites")
        print(f"📁 Location: {self.tests_dir}/")
        print("\n⏱️  Estimated Run Times:")
        print("  01_profile_account_tests.yaml:    ~2.0 min (15 steps)")
        print("  02_pet_management_tests.yaml:     ~3.0 min (20 steps)")
        print("  03_shop_commerce_tests.yaml:      ~2.5 min (18 steps)")
        print("  04_device_management_tests.yaml:  ~5.0 min (33 steps)")
        print("  05_insights_analytics_tests.yaml: ~5.0 min (36 steps)")
        print("  06_logout_login_tests.yaml:       ~2.5 min (20 steps)")
        print("  " + "-" * 50)
        print("  Total in series:                  ~20.0 min (142 steps)")
        print("\nTest files:")
        for test in tests_created:
            print(f"  - {test}")
        
        return tests_created


def main():
    organizer = TestOrganizer()
    organizer.create_all_tests()


if __name__ == "__main__":
    main()

