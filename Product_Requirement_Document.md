# Product Requirements Document: ViiRaa iOS App

## Document Information

- **Version**: 2.5
- **Last Updated**: 2025-12-10
- **Product**: ViiRaa iOS Mobile Application
- **Status**: Updated with Glucose Prediction Feature - December 2025

## Executive Summary

ViiRaa will launch a native iOS application to provide users with a seamless mobile experience. The app follows a pragmatic three-phase strategy:

**Phase 1 (Week 1)**: Deploy a WebView-based MVP to TestFlight for internal team validation, bypassing App Store approval requirements. This enables rapid development (3-5 days) and immediate feedback.

**Phase 2 (Week 2-4)**: Add Apple HealthKit integration and Junction SDK to strengthen the App Store approval case by demonstrating native iOS functionality beyond web content. HealthKit will enable reading CGM data, weight tracking, and activity metrics—capabilities that justify the app's existence as a native iOS experience. Junction SDK provides unified API access to 300+ health devices and HIPAA-compliant cloud storage for ML training, with an expected 3-hour data delay due to HealthKit API limitations.

**Phase 3 (Week 7-12, Optional)**: If the 3-hour data delay is validated as a business blocker, implement BLE Follow Mode integration to reduce glucose data latency to 1-5 minutes. This approach, inspired by xDrip4iOS, monitors official Abbott Lingo app communications without reverse-engineering proprietary protocols, maintaining legal compliance and App Store guidelines. The hybrid architecture keeps Junction as the primary data source for ML training while BLE Follow Mode provides real-time user insights.

This strategy addresses the critical user acquisition gap where potential users instinctively search for a mobile app rather than visiting the website, while mitigating the high risk of App Store rejection for WebView-only applications and providing a path to real-time glucose monitoring if needed.

---

## 1. Problem Statement

### Current Situation

- Users' first instinct when learning about ViiRaa is to search for and download an iOS app
- The company currently only offers a web-based dashboard experience
- Directing users to the website creates friction in the onboarding process
- Lack of mobile presence impacts user acquisition and retention for bootcamp participants

### User Pain Points

- No native mobile app available in the App Store
- Less cohesive experience compared to native apps
- Reduced engagement due to web-only access
- Missing mobile-specific features (push notifications, offline support)

---

## 2. Product Vision & Goals

### Vision

Create a native iOS application that provides users with seamless access to their ViiRaa dashboard and community features, delivered through a mobile-first experience.

### Primary Goals

1. **User Acquisition**: Enable App Store discoverability to capture users who search for mobile apps
2. **Code Reusability**: Maximize existing web codebase through WebView integration
3. **Time to Market**: Launch MVP within shortest possible timeframe
4. **Feature Parity**: Provide equivalent functionality to web dashboard in mobile format
5. **Foundation for Growth**: Establish iOS presence that can evolve into fully native features

### Success Metrics

**TestFlight Phase:**

- TestFlight build deployed for internal team testing
- User dashboard accessible via mobile app
- Authentication flow working seamlessly
- PostHog analytics tracking mobile sessions

**App Store Launch:**

- App Store listing live with Apple HealthKit integration
- User engagement metrics comparable to or exceeding web platform
- Positive App Store ratings (target: 4.0+)
- App Store approval achieved on first or second submission

**Phase 2 (Chat Integration):**

- miniViiRaa chat functionality integrated
- Chat engagement metrics tracked
- Migration from Telegram completed

---

## 3. Target Audience

### Primary Users

- ViiRaa bootcamp participants
- Health-conscious individuals interested in glucose monitoring
- Users who prefer mobile-first experiences
- iOS users (iPhone and iPad)

### User Personas

Based on user research and segmentation analysis (see: `Who is our Persona.csv`), ViiRaa targets three distinct personas:

**Persona 1: Young Professional Female**

- **Age**: 25-35 (pre-kids)
- **Profile**: Professional income, gym/yoga habits, fertility awareness
- **Primary Goal**: Lose weight sustainably and improve energy while managing busy schedule
- **Health Context**: Energy, Fitness, Overweight, Fertility needs
- **Why Now**: Upcoming life event (wedding, pregnancy/egg freezing), body composition goals, performance at work
- **Key Behaviors**: Pre-kids professional, gym/yoga habits, fertility-conscious
- **App Usage**: High mobile engagement, prefers tracking apps for busy lifestyle

**Persona 2: Precondition 50+**

- **Age**: 50+ (verify: potentially 35+ due to parenting attention tradeoff)
- **Profile**: Prediabetes or Type 2 risk, overweight, awareness via annual checkup redlines
- **Primary Goal**: Prevent diabetes progression and regain energy
- **Health Context**: Prediabetes, Type 2 Diabetes risk, Overweight, Annual report redlines
- **Why Now**: Recent redline in annual report or physician warning, desire to avoid medications
- **Key Behaviors**: Health-motivated but may have tech onboarding friction
- **App Usage**: Values guided coaching over DIY tools

**Persona 3: Bio-Hacker**

- **Age**: 20-40
- **Profile**: Early adopter, fitness-focused, enjoys data and experiments
- **Primary Goal**: Optimize productivity, energy, and training using glucose insights
- **Health Context**: Energy, Fitness, Productivity
- **Why Now**: Training cycles, performance plateaus, curiosity about glucose
- **Key Behaviors**: Data-driven, experiments with health optimization
- **App Usage**: High engagement with health tracking apps, expects advanced analytics
- **Risk**: May churn after short learning period if not engaged with guided program

---

## 4. Product Scope

### Phase 1: MVP - Dashboard Integration (Immediate)

#### 4.1 In Scope

**Core Features:**

- Native iOS app shell with tab-based navigation
- WebView integration for user dashboard (profile section)
- Two main tabs:
  - **Dashboard Tab**: Embedded web dashboard experience
  - **Chat Tab**: Interim WhatsApp redirect (preparation for Phase 2)
    - Guide users to WhatsApp: https://wa.me/18882087058
    - Provides immediate support channel until native chat is ready
    - Clear messaging about temporary nature of WhatsApp integration
- User authentication flow
- Basic app lifecycle management
- App Store submission and deployment

**Technical Requirements:**

- iOS 14.0+ support
- iPhone and iPad compatibility
- Portrait and landscape orientation support
- WebView with full JavaScript bridge for seamless integration
- Secure authentication token handling
- Deep linking support for web navigation

**Design Requirements:**

- Native iOS navigation patterns (tab bar)
- Consistent branding with web platform
- **App Icon & Logo**: Use square logo asset
  - Asset location: `/Users/barack/Downloads/Xcode/Xcode/ViiRaa-Logo-Square.png`
  - Apply to app icon, splash screen, and branding elements
- Loading states and error handling
- Responsive layout for different device sizes

#### 4.2 Prioritized for Future Phases

**Phase 2 (Critical-to-have, but not must):**

- Push notifications (for engagement and coaching reminders)
- Apple HealthKit integration (CRITICAL for iOS App Store approval strategy)
  - Read CGM data (glucose readings)
  - Read weight data
  - Read activity/fitness data
  - Write ViiRaa insights to Health app
  - Native glucose data display view with charts and statistics
  - Real-time glucose monitoring and trends
- **Junction SDK Integration** (for bio data synchronization and ML training)
  - Integrate Vital Mobile SDK for unified health data access
  - Enable automated HealthKit data sync to Junction cloud
  - Support 300+ health devices through Junction's unified API
  - Enable HIPAA-compliant cloud storage for ML model training
  - Reference: `/Users/barack/Downloads/Xcode/3rd_Party_Bio_Data_Integration_Report.md`
  - **Limitation**: 3-hour data delay due to Apple HealthKit API restrictions
- **BLE Follow Mode Integration** (for real-time glucose monitoring)
  - Implement Follower Mode approach inspired by xDrip4iOS
  - Read glucose data from official Abbott Lingo app via BLE monitoring
  - Reduce data latency to 1-5 minutes (vs. 3-hour HealthKit delay)
  - Support for Abbott Lingo (streams continuously via Bluetooth, measures every minute)
  - Requires users to run official CGM app alongside ViiRaa app
  - **Legal Compliance**: Does not reverse-engineer proprietary protocols; reads from official app communications
  - Reference: `/Users/barack/Downloads/Xcode/3rd_Party_Bio_Data_Integration_Report.md` Section 2
- **Glucose Prediction Feature** (WebView integration)
  - Reuse existing web implementation from `/Users/barack/Downloads/251210-viiraalanding-main`
  - User Journey:
    1. User navigates to Glucose Tab in iOS app
    2. User accesses https://www.viiraa.com/predict-glucose to view all predictions or create new prediction
    3. Backend generates prediction ID for each user operation
    4. User views individual prediction charts at https://www.viiraa.com/predict-glucose/{prediction-id}
  - **Implementation**: WebView-based integration (no code rewrite required)
- Android app development (keep cross-platform considerations in mind during iOS development)

**Nice-to-have (Post-MVP):**

- iPad optimization (while MVP supports iPad, UI optimization deferred)
- Fully native UI components (replacing WebView gradually)
- Offline functionality
- Apple Watch integration
- Widget support
- Advanced iOS-specific features

### Phase 2: Chat Integration (Future)

#### 5.1 Phase 1 Interim Solution

**WhatsApp Redirect** (Temporary until native chat is ready):

- Chat tab includes button/link to WhatsApp: https://wa.me/18882087058
- User messaging: "Chat with our team on WhatsApp while we build our native chat feature"
- Provides immediate support channel for users during MVP phase
- Simple to implement and replace in Phase 2

#### 5.2 Phase 2 Native Chat (In Scope)

- Integration of miniViiRaa (AI coach) chat functionality into iOS app
- **Preferred Approach**: WebView-based chat interface
  - Enables web access to miniViiRaa in mid-term roadmap
  - Maintains code reusability across platforms
  - Faster iteration and deployment
- Evaluation and implementation of Mattermost (open-source alternative to Telegram)
- Real-time messaging capabilities
- Migration path from existing Telegram dependency
- **Remove WhatsApp redirect** and replace with native chat interface

#### 5.3 Timeline

- **Phase 1**: WhatsApp redirect (immediate - part of MVP)
- **Phase 2**: After Phase 1 (Dashboard) is complete and deployed
- Goal: Consolidate all user interactions within native app

#### 5.4 Rationale

- **Interim WhatsApp**: Avoids empty Chat tab, provides immediate user support
- Reduce dependency on third-party platform (Telegram)
- Provide unified user experience across web and mobile
- Enable better integration with bootcamp content and user data
- Improve community engagement
- Support future web-based AI coach access

---

## 5. App Store Approval Strategy

### Challenge: WebView-Only Apps

Apple's App Store review guidelines are strict about apps that are primarily WebView wrappers. Apps that simply display web content without significant native functionality are often rejected.

### Two-Phase Deployment Strategy

#### Phase 1: TestFlight Internal Testing (Week 1)

- **Goal**: Validate core functionality and user experience with internal team
- **Advantage**: TestFlight does NOT require App Store approval for internal testing
- **Scope**: WebView-based dashboard with authentication
- **Timeline**: Deploy within 1 week
- **Outcome**: Internal demo and validation before investing in App Store submission

#### Phase 2: App Store Submission (Week 2-4)

- **Goal**: Public launch with App Store approval
- **Strategy**: Add Apple HealthKit integration to demonstrate native iOS value
- **Key Native Features**:
  - **Apple HealthKit Integration** (CRITICAL):
    - Read CGM data (glucose readings from compatible devices)
    - Read weight data from Health app
    - Read activity/fitness data
    - Write ViiRaa insights and recommendations to Health app
  - Native authentication flow with biometric support
  - Native tab navigation and UI shell
  - Push notification infrastructure (implemented in future phase)
- **Approval Case**: HealthKit integration demonstrates genuine iOS platform value and justifies app existence beyond web access

### Why HealthKit is Critical

1. **Native Functionality**: HealthKit is iOS-exclusive and cannot be replicated in a web browser
2. **User Value**: Integrates ViiRaa data with Apple's health ecosystem
3. **Technical Depth**: Shows meaningful iOS platform integration
4. **Approval Strength**: Demonstrates app is not merely a website wrapper
5. **Future Foundation**: Enables advanced health tracking features for roadmap

### Apple Guidelines Compliance

The app will comply with:

- **Guideline 4.2 (Minimum Functionality)**: HealthKit integration provides significant native value
- **Guideline 2.5.2 (Software Requirements)**: Uses native iOS APIs and frameworks
- **Guideline 5.1.1 (Privacy - Data Collection)**: Proper HealthKit permission handling and privacy policy

---

## 6. Technical Architecture

### High-Level Architecture

```
┌─────────────────────────────────────┐
│        iOS Native Shell             │
│  ┌───────────────────────────────┐  │
│  │   Tab Bar Navigation          │  │
│  ├───────────────────────────────┤  │
│  │  Dashboard Tab │  Chat Tab    │  │
│  └────────┬────────┴──────────────┘  │
│           │                          │
│  ┌────────▼──────────────┐          │
│  │  WKWebView Container  │          │
│  │  ┌─────────────────┐  │          │
│  │  │  Web Dashboard  │  │          │
│  │  │  (React App)    │  │          │
│  │  └─────────────────┘  │          │
│  └───────────────────────┘          │
└─────────────────────────────────────┘
            │
            │ HTTPS
            ▼
┌─────────────────────────────────────┐
│   Existing Web Infrastructure       │
│   - React Dashboard                 │
│   - Supabase Auth                   │
│   - Backend API                     │
└─────────────────────────────────────┘
```

### Technology Stack

- **Language**: Swift 5.9+ (SwiftUI preferred) or React Native
- **Minimum iOS Version**: iOS 14.0
- **WebView**: WKWebView for dashboard integration
- **Authentication**: Integration with existing Supabase Auth
- **Storage**: Keychain for secure token storage
- **Navigation**: Native tab-based navigation

### WebView Integration Strategy

1. **URL Loading**: Load dashboard URL (`/dashboard`) in WKWebView
2. **Authentication**: Pass auth tokens securely to WebView
3. **JavaScript Bridge**: Enable bidirectional communication between native and web
4. **Navigation Handling**: Intercept and handle navigation events
5. **Cookie Management**: Sync authentication cookies

---

## 6. User Experience & User Flows

### User Flow: First Launch

1. User downloads app from App Store
2. App opens to login/signup screen
3. User authenticates (Google OAuth or email/password)
4. User lands on Dashboard tab
5. WebView loads user's dashboard content
6. User can navigate between Dashboard and Chat tabs

### User Flow: Returning User

1. User opens app
2. App auto-authenticates using stored credentials
3. Dashboard loads immediately
4. User browses content seamlessly

### User Flow: Sign Out

- Sign-out functionality is handled entirely within the web interface
- When user signs out in web dashboard, web app sends "logout" message to iOS
- iOS native app receives the message and clears local authentication state
- User is returned to login screen
- Simplifies architecture by delegating authentication management to web
- Reduces redundancy between iOS native and web implementations

### User Flow: Authentication Session Sharing

**CRITICAL REQUIREMENT**: User must ONLY authenticate ONCE in the iOS app. No duplicate login prompts should appear.

1. User authenticates via iOS native login screen (Google OAuth or email/password)
2. iOS app receives full Supabase session (access_token, refresh_token, user data)
3. Session is securely stored in iOS Keychain
4. When loading web dashboard in WebView:
   - iOS app injects complete Supabase session into WebView's localStorage
   - Session is injected before page load (via WKUserScript) and after page load (via evaluateJavaScript)
   - Web dashboard's Supabase client reads session from localStorage
   - User is automatically authenticated in web dashboard - **no second login required**
   - **KNOWN ISSUE**: Currently users are being asked to login twice (native + web). This must be fixed by ensuring proper session injection and validation.
5. Web dashboard recognizes existing session and displays authenticated content
6. User has seamless single sign-on experience across iOS and web

**Testing Requirements**:

- Test with both email/password AND Google OAuth authentication
- Test account: reviewer@viiraa.com / ReviewPassword123
- Verify NO duplicate login prompts appear
- Verify Google Sign-In does not cause crashes

### Key Screens

1. **Splash Screen**: ViiRaa branding with square logo (`/Users/barack/Downloads/Xcode/Xcode/ViiRaa-Logo-Square.png`)
2. **Authentication Screen**: Login/signup options
3. **Dashboard Tab**: WebView with user dashboard
4. **Chat Tab**: WhatsApp redirect (Phase 1) → Native chat interface (Phase 2)
   - **Interim Solution**: Button/link to open WhatsApp chat: https://wa.me/18882087058
   - **User Messaging**: "Chat with our team on WhatsApp while we build our native chat feature"
   - **Phase 2**: Replace with integrated miniViiRaa chat interface
5. **Settings Screen**: Native settings screen with HealthKit permissions management
   - **CRITICAL**: Must allow users to re-grant HealthKit access if denied initially
   - **BUG FIX REQUIRED**: Currently shows "Access denied" even when HealthKit permissions are granted
     - Investigate permission status checking logic
     - Ensure proper HealthKit authorization status retrieval
     - Verify permission persistence across app launches
   - Provide clear explanation of HealthKit benefits
   - Direct link to iOS Settings for permission changes
   - Display current permission status accurately
   - Handle edge cases where permissions are partially granted

---

## 7. Development Plan

### Timeline

**Short-term (1 week or less):**

- **PRD Completion**: Immediate
- **Software Design Document (SD)**: 1-2 days after PRD approval
- **iOS MVP Development (WebView)**: 3-5 days
- **Internal Demo**: Demo with WebView for internal team
- **TestFlight Deployment**: Launch in TestFlight (NO App Store approval needed for internal testing)

**Mid-term (Post TestFlight validation):**

- **Apple HealthKit Integration**: Add HealthKit to strengthen App Store approval case
- **Testing & QA**: 1 week
- **App Store Submission**: 1-2 weeks (Apple review process)
- **Total to Public Launch**: 3-4 weeks from start

### Milestones

**Phase 1: TestFlight MVP (Week 1)**

1. ✅ PRD approval
2. ✅ SD completion
3. 🔲 Development environment setup
4. 🔲 Basic app shell with tab navigation
5. 🔲 WebView integration with dashboard
6. 🔲 Authentication flow implementation. Should be handled by dashboard as well.
7. 🔲 **CRITICAL BUGS TO FIX**:
   - 🔲 Fix Google Sign-In crash (test with reviewer@viiraa.com / ReviewPassword123)
   - 🔲 Fix duplicate login prompts (native iOS + WebView)
   - 🔲 Implement proper session injection for single sign-on
8. 🔲 Update app branding to use square logo
9. 🔲 **Chat Tab WhatsApp Integration**:
   - 🔲 Implement WhatsApp redirect button: https://wa.me/18882087058
   - 🔲 Add user-friendly messaging about interim solution
   - 🔲 Design UI for smooth transition to WhatsApp
10. 🔲 Internal demo with team
11. 🔲 TestFlight deployment for internal testing

**Phase 2: App Store Preparation (Week 2-4)**

12. 🔲 Apple HealthKit integration (CRITICAL for approval)
    - CGM data reading capability
    - Weight tracking read capability
    - Activity/fitness data read capability
13. 🔲 Junction SDK Integration
    - Sign contract and BAA with Junction
    - Integrate Vital Mobile SDK into ViiRaa iOS app
    - Configure automated data sync (Junction → HIPAA-compliant cloud)
    - Reference: `/Users/barack/Downloads/Xcode/3rd_Party_Bio_Data_Integration_Report.md`
    - **Note**: Expect 3-hour data delay due to HealthKit limitations (acceptable for ML training)
14. 🔲 Settings screen with HealthKit permissions management
    - **FIX BUG**: Resolve "Access denied" display when permissions are actually granted
    - Display current permission status accurately
    - Provide re-grant flow for denied permissions
    - Link to iOS Settings app
    - User-friendly explanations
    - Test permission status persistence across app launches
15. ✅ Glucose Prediction Feature integration - **IMPLEMENTED 2025-12-10**
    - Integrate WebView access to https://www.viiraa.com/predict-glucose from Glucose Tab
    - Reuse existing web implementation (no code rewrite)
    - Source code reference: `/Users/barack/Downloads/251210-viiraalanding-main`
    - **Implementation**: `Xcode/Features/HealthKit/GlucosePredictionWebView.swift`
16. 🔲 Enhanced native features to strengthen approval case
17. 🔲 Marketing materials preparation (aligned with landing page updates)
18. 🔲 App Store submission
19. 🔲 App Store approval and public launch

**Phase 3: BLE Follow Mode Integration (Week 7-12) - Optional**

20. 🔲 Evaluate data latency impact from Phase 2
    - Assess if 3-hour delay affects product/science goals
    - Collect user feedback on data freshness requirements
    - **Go/No-go decision**: Proceed with BLE Follow Mode only if latency is validated as blocker
21. 🔲 BLE Follow Mode Research & Development
    - Study xDrip4iOS implementation approach
    - Develop Follower Mode data interceptor for Abbott Lingo
    - Test compatibility with official Abbott Lingo app
22. 🔲 BLE Follow Mode Implementation
    - Implement BLE monitoring for Abbott Lingo (continuous streaming, 1-minute measurement)
    - Build user onboarding flow explaining dual-app requirement
    - Create settings UI for BLE Follow Mode configuration
23. 🔲 Hybrid Data Pipeline Architecture
    - Junction SDK for historical data and ML training (3-hour delay acceptable)
    - BLE Follow Mode for real-time user insights (1-5 minute latency)
    - Cross-validation between both data sources
    - Fallback to HealthKit/Junction if BLE unavailable
24. 🔲 Testing & Validation
    - Test with TestFlight before App Store submission
    - Verify legal compliance (no reverse engineering of proprietary protocols)
    - Document user setup instructions
    - Ensure App Store guidelines compliance
25. 🔲 BLE Follow Mode Launch
    - Deploy to production with feature flag
    - Monitor data quality and latency metrics
    - Collect user feedback on setup complexity

### Development Process

- **Updates**: Daily progress reports
- **Code Reviews**: Regular review cycles
- **Testing**: Continuous testing on physical devices
- **Documentation**: Maintain technical documentation alongside development

---

## 8. Dependencies & Requirements

### Access Requirements

- Apple Developer Account access
- Access to ViiRaa backend API and authentication system
- Supabase project credentials
- App Store Connect access for deployment

### External Dependencies

- Existing web dashboard must be mobile-responsive
- Backend API must support mobile app authentication
- Supabase Auth configuration for mobile

---

## 9. Risks & Mitigations

| Risk                                                     | Impact             | Probability      | Mitigation                                                                                                                                                                                                             |
| -------------------------------------------------------- | ------------------ | ---------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **App Store rejection due to WebView-only app**    | **Critical** | **High**   | **Two-phase approach: (1) TestFlight for internal validation bypasses App Store review, (2) Add Apple HealthKit integration before public submission to strengthen approval case with native iOS functionality** |
| **App crashes with Google Sign-In authentication** | **High**     | **High**   | **CRITICAL BUG: App crashes when signing in with Google account. Must fix authentication flow to handle Google OAuth properly. Test with reviewer@viiraa.com / ReviewPassword123**                               |
| **Duplicate login prompts (native + web)**         | **High**     | **High**   | **CRITICAL UX ISSUE: Users asked to login twice - once in native iOS and once in WebView. Session injection must be implemented correctly to enable true SSO experience**                                        |
| **HealthKit "Access denied" bug**                  | **High**     | **High**   | **CRITICAL BUG: Settings shows "Access denied" even when HealthKit permissions are granted. Must fix permission status checking logic and ensure proper authorization status retrieval**                         |
| **HealthKit permission re-grant not possible**     | **Medium**   | **High**   | **Add Settings page with HealthKit permissions management. If user denies access initially, provide clear path to re-enable in app settings with link to iOS Settings**                                          |
| **3-hour data delay affects product value**        | **Medium**   | **Medium** | **Phased approach: (1) Launch with Junction/HealthKit, evaluate impact, (2) If validated as blocker, proceed with BLE Follow Mode integration in Phase 3 to reduce latency to 15-30 minutes**                    |
| **BLE Follow Mode legal/compliance risks**         | **High**     | **Low**    | **Use Follower Mode approach only (no reverse engineering). Monitor official app communications without breaking encryption. Test via TestFlight before App Store submission. Maintain Junction as fallback**    |
| **Users need support before native chat is ready** | **Medium**   | **Medium** | **Interim Solution: Implement WhatsApp redirect (https://wa.me/18882087058) in Chat tab with clear messaging. Replace with native chat in Phase 2**                                                              |
| **BLE Follow Mode maintenance burden**             | **Medium**   | **Medium** | **Hybrid architecture: Keep Junction SDK as primary data source and fallback. BLE Follow Mode for real-time only. Cross-validate data between sources**                                                          |
| **User confusion with dual-app requirement (BLE)** | **Medium**   | **Medium** | **Clear onboarding documentation explaining why official CGM app must run. Provide setup guides with screenshots. Only implement if latency is validated business blocker**                                      |
| WebView performance issues                               | Medium             | Low              | Optimize web dashboard for mobile, implement loading states                                                                                                                                                            |
| Authentication complexity                                | Medium             | Medium           | Use existing Supabase mobile SDKs, thorough testing                                                                                                                                                                    |
| Web dashboard not mobile-friendly                        | High               | Low              | Verify responsive design, make CSS adjustments if needed                                                                                                                                                               |
| Delayed timeline for HealthKit integration               | Medium             | Medium           | Prioritize TestFlight launch first, add HealthKit in parallel for App Store submission                                                                                                                                 |
| Android platform fragmentation when expanding            | Medium             | Low              | Design with cross-platform in mind from start; WebView approach supports this strategy                                                                                                                                 |

---

## 10. Success Criteria

### TestFlight MVP Launch Criteria (Week 1)

- [ ] TestFlight build successfully deployed for internal testing
- [ ] Users can authenticate using existing credentials
- [ ] Dashboard loads and functions correctly in WebView
- [ ] **Chat Tab WhatsApp Integration**
  - [ ] WhatsApp redirect button implemented (https://wa.me/18882087058)
  - [ ] Clear user messaging about interim solution
  - [ ] Smooth UI/UX for external app transition
- [ ] No critical bugs or crashes
- [ ] Internal team can demo and validate user experience
- [ ] PostHog analytics tracking implemented for mobile

### App Store Public Launch Criteria (Week 3-4)

- [X] Apple HealthKit integration implemented
  - [X] CGM data read capability
  - [X] Weight tracking read capability
  - [X] Activity/fitness data read capability
  - [X] Native glucose data display view
  - [X] Interactive glucose charts with time-in-range visualization
  - [X] Glucose statistics dashboard
  - [X] Multi-timeframe data views (today, week, month)
  - [ ] **HealthKit permissions management in Settings**
    - [ ] **BUG FIX**: Resolve "Access denied" display bug when permissions are granted
    - [ ] Settings screen with accurate HealthKit permission status display
    - [ ] Ability to re-grant HealthKit access after initial denial
    - [ ] Clear instructions and link to iOS Settings app
    - [ ] User-friendly explanation of why HealthKit access is beneficial
    - [ ] Verify permission status persistence across app sessions
- [X] **Glucose Prediction Feature integrated** - ✅ IMPLEMENTED 2025-12-10
  - [X] WebView access to https://www.viiraa.com/predict-glucose from Glucose Tab
  - [X] User can view all predictions and create new predictions
  - [X] Individual prediction charts accessible at https://www.viiraa.com/predict-glucose/{prediction-id}
  - [X] Implementation: `Xcode/Features/HealthKit/GlucosePredictionWebView.swift`
- [ ] **Authentication bugs fixed**
  - [ ] Google Sign-In crash resolved (test with reviewer@viiraa.com)
  - [ ] Single sign-on working correctly (no duplicate login prompts)
  - [ ] Session injection properly implemented for WebView
- [ ] **App branding updated**
  - [ ] Square logo implemented in app icon and splash screen
  - [ ] Asset location: `/Users/barack/Downloads/Xcode/Xcode/ViiRaa-Logo-Square.png`
- [ ] App successfully submitted and approved on App Store
- [ ] Marketing materials prepared (aligned with landing page updates)
- [X] Native iOS features beyond WebView demonstrate value for approval

### Phase 2 Success Criteria (Chat & Engagement)

- [ ] **Transition from WhatsApp to Native Chat**
  - [ ] Remove WhatsApp redirect from Chat tab
  - [ ] Notify existing users about native chat availability
- [ ] miniViiRaa (AI coach) chat functionality integrated via WebView
- [ ] Mattermost or alternative chat backend evaluated and implemented
- [ ] Users can send and receive messages within app
- [ ] Migration from Telegram completed
- [ ] Push notifications implemented for engagement and coaching reminders
- [ ] Web-based AI coach access enabled for cross-platform consistency

### Phase 3 Success Criteria (BLE Follow Mode - Optional)

- [ ] **Data Latency Evaluation Complete**
  - [ ] Determine if 3-hour delay impacts product/science goals
  - [ ] Collect user feedback on data freshness requirements
  - [ ] Go/No-go decision documented with business justification
- [ ] **BLE Follow Mode Implementation** (if proceeding)
  - [ ] Follower Mode data interceptor for Abbott Lingo working
  - [ ] Data latency reduced to 1-5 minutes
  - [ ] User onboarding guides created for dual-app setup
  - [ ] Settings UI for BLE configuration implemented
- [ ] **Hybrid Architecture Validation**
  - [ ] Junction SDK continues as primary data source for ML training
  - [ ] BLE Follow Mode provides real-time user insights
  - [ ] Cross-validation between data sources implemented
  - [ ] Fallback to HealthKit/Junction working correctly
- [ ] **Legal & Compliance**
  - [ ] No reverse engineering of proprietary protocols confirmed
  - [ ] TestFlight testing completed successfully
  - [ ] App Store guidelines compliance verified
  - [ ] App Store approval achieved with BLE Follow Mode

### Long-term Success Metrics

- App Store downloads: 100+ in first month
- Daily active users (DAU) comparable to web platform
- Session duration: Average 5+ minutes
- Crash-free rate: >99%
- User retention: >60% after 7 days

---

## 11. Authentication & Session Management

### Authentication Requirements

1. **Single Sign-On (SSO) Experience**

   - User should only authenticate once on iOS app
   - Web dashboard should automatically recognize iOS authentication
   - No duplicate login prompts
2. **Session Injection Strategy**

   - iOS app must inject complete Supabase session into WebView
   - Session format must match Supabase's expected structure:
     - `access_token`: JWT access token
     - `refresh_token`: Refresh token for session renewal
     - `expires_in`: Token expiration time
     - `token_type`: Token type (typically "bearer")
     - `user`: User object with id, email, aud, and role
   - Session must be stored in localStorage with correct Supabase key format
   - Injection must occur at two points:
     - Before page load (via WKUserScript at document start)
     - After page load (via evaluateJavaScript) to ensure persistence
3. **Security Considerations**

   - Tokens must be properly escaped for JavaScript injection
   - Session data stored in iOS Keychain for secure persistence
   - Automatic session refresh handled by Supabase client

### Implementation Details

**iOS Native Authentication:**

- Supabase Swift SDK handles authentication flow
- Full session object received and stored securely
- Session shared with WebView via JavaScript injection

**WebView Session Injection:**

- Complete session data injected into localStorage
- Storage key format: `sb-{project-id}-auth-token`
- Custom events dispatched to notify web app of authentication state
- Global flags set for iOS app detection (`window.iosAuthenticated`, `window.iosSession`)

## 12. Decisions Log

### Resolved Questions

1. **Should the MVP include push notifications, or defer to Phase 2?**

   - **Decision**: Defer to Phase 2 (critical-to-have, but not must for MVP)
   - **Rationale**: Focus MVP on core dashboard functionality; add notifications for engagement in Phase 2
2. **What analytics platform should be used for mobile tracking?**

   - **Decision**: PostHog (existing web analytics platform)
   - **Implementation**: PostHog is compatible with mobile and provides cross-platform consistency
   - **Reference**: https://us.posthog.com/project/224201
3. **Are there specific App Store marketing materials needed?**

   - **Decision**: Align with landing page marketing materials first, then adapt for App Store
   - **Timeline**: Marketing materials will be updated on landing page, then used for App Store submission
4. **Should iPad optimization be prioritized for MVP or post-launch?**

   - **Decision**: Nice-to-have (not prioritized for MVP)
   - **Categorization**:
     - Must-to-have: iPhone support with WebView dashboard
     - Critical-to-have: HealthKit integration for App Store approval
     - Nice-to-have: iPad UI optimization
5. **What is the preferred approach for chat integration (native vs WebView)?**

   - **Decision**: WebView-based chat interface
   - **Rationale**:
     - Supports mid-term roadmap for web-based miniViiRaa (AI coach) access
     - Maintains code reusability across platforms
     - Faster iteration and deployment
6. **Do we need Android app in parallel, or iOS-first strategy?**

   - **Decision**: iOS-first strategy, with Android in future roadmap
   - **Implementation Strategy**:
     - Prioritize iOS MVP and TestFlight launch
     - Design with cross-platform considerations (WebView wrapper approach supports this)
     - Android app is critical-to-have for future, but not MVP blocker
7. **Should sign-out be handled natively in iOS or by the web interface?**

   - **Decision**: Sign-out handled entirely by web interface
   - **Rationale** (Lei's feedback):
     - Simplifies architecture and reduces redundancy
     - Avoids duplicate sign-out implementations in iOS and web
     - Web-based sign-out is more maintainable and consistent
     - Reduces iOS native complexity
   - **Implementation**: Web sends "logout" message to iOS via JavaScript bridge
   - **Date**: 2025-10-20
8. **Should iOS authentication session be shared with web dashboard automatically?**

   - **Decision**: Yes, full session must be shared to enable single sign-on
   - **Rationale**:
     - Prevents double login requirement (iOS + web)
     - Provides seamless user experience
     - Maintains authentication state consistency
   - **Implementation**: Complete Supabase session injected into WebView localStorage
   - **Date**: 2025-10-20
9. **What should users see in the Chat tab before native chat is ready?**

   - **Decision**: Implement WhatsApp redirect as interim solution
   - **WhatsApp Link**: https://wa.me/18882087058
   - **Rationale**:
     - Provides immediate support channel for users
     - Avoids dead/empty UI in Chat tab during MVP phase
     - Maintains user engagement until native chat is built
     - Simple to implement and replace later
   - **User Experience**: Clear messaging that this is temporary, native chat coming soon
   - **Phase 2 Migration**: Replace with WebView-based miniViiRaa chat interface
   - **Date**: 2025-11-20
10. **Why is Settings showing "Access denied" even when HealthKit permissions are granted?**

    - **Issue Identified**: HealthKit permission status checking logic has a bug
    - **Impact**: High - Users granted permissions but see "Access denied" message
    - **Required Fix**:
      - Debug authorization status retrieval code
      - Verify correct HealthKit permission checking API usage
      - Test permission persistence across app launches
      - Handle edge cases (partial permissions, delayed authorization)
    - **Priority**: Critical bug fix for App Store launch
    - **Date**: 2025-11-20
11. **Should ViiRaa integrate with Junction for bio data synchronization?**

    - **Decision**: Yes, integrate Junction SDK for unified health data access and ML training
    - **Rationale**:
      - Junction provides unified API for 300+ health devices
      - Enables HIPAA-compliant cloud storage for ML model training
      - Supports automated HealthKit data sync
      - Y Combinator-backed with $18M Series A funding
    - **Implementation**: Integrate Vital Mobile SDK, sign BAA with Junction
    - **Trade-off**: 3-hour data delay due to HealthKit limitations (acceptable for ML training)
    - **Reference**: `/Users/barack/Downloads/Xcode/3rd_Party_Bio_Data_Integration_Report.md`
    - **Date**: 2025-11-25
12. **How can ViiRaa achieve real-time glucose data access with lower latency?**

    - **Decision**: Implement BLE Follow Mode as Phase 3 optional enhancement (if latency is validated as blocker)
    - **Rationale**:
      - Junction/HealthKit enforces 3-hour data delay (Apple API limitation)
      - BLE Follow Mode reduces latency to 1-5 minutes
      - Inspired by xDrip4iOS Follower Mode approach
      - Does NOT reverse-engineer proprietary protocols (legal compliance)
      - Monitors official Abbott Lingo app communications
    - **Technical Specifications**:
      - Abbott Lingo: Measures every minute, streams continuously via Bluetooth
      - Requires users to run official CGM app alongside ViiRaa
    - **Implementation Strategy**:
      - Phase 2: Launch with Junction/HealthKit, evaluate data latency impact
      - Phase 3: If latency validated as business blocker, implement BLE Follow Mode
      - Hybrid architecture: Junction for ML training, BLE for real-time insights
      - Maintain Junction as fallback and primary data source
    - **Legal & Compliance**:
      - Follower Mode does not violate manufacturer ToS
      - No encryption breaking or firmware reverse engineering
      - App Store compliant (similar to xDrip4iOS)
    - **Reference**: `/Users/barack/Downloads/Xcode/3rd_Party_Bio_Data_Integration_Report.md` Section 2
    - **Date**: 2025-11-25

13. **Should ViiRaa implement a Glucose Prediction feature in the iOS app?**

    - **Decision**: Yes, integrate Glucose Prediction feature via WebView
    - **Rationale**:
      - Feature already implemented in web version (no code rewrite required)
      - Reuse existing web implementation from `/Users/barack/Downloads/251210-viiraalanding-main`
      - WebView-based integration maintains code reusability
    - **User Journey**:
      1. User navigates to Glucose Tab in iOS app
      2. User accesses https://www.viiraa.com/predict-glucose to view all predictions or create new prediction
      3. Backend generates prediction ID for each user operation
      4. User views individual prediction charts at https://www.viiraa.com/predict-glucose/{prediction-id}
    - **Implementation**: WebView integration, no new native code required
    - **Date**: 2025-12-10

---

## 12. Bluetooth Low Energy (BLE) Follow Mode Technical Specifications

### Overview

BLE Follow Mode is an enhancement to reduce glucose data latency from 3 hours (HealthKit limitation) to 1-5 minutes. This feature is inspired by the xDrip4iOS open-source project and provides real-time glucose monitoring through Bluetooth Low Energy (BLE) monitoring of the official Abbott Lingo app.

### Data Latency Comparison

| Data Source                    | Latency     | Use Case                         | Implementation Phase |
| ------------------------------ | ----------- | -------------------------------- | -------------------- |
| Apple HealthKit (via Junction) | 3 hours     | ML training, historical analysis | Phase 2 (Primary)    |
| BLE Follow Mode (Abbott Lingo) | 1-5 minutes | Real-time user insights          | Phase 3 (Optional)   |

### Supported CGM Device

**Abbott Lingo:**

- **Hardware**: Built on Abbott FreeStyle Libre technology (10+ million users)
- **Sensor Duration**: Up to 14 days
- **Measurement Frequency**: Measures glucose every minute
- **Transmission Method**: Streams continuously via Bluetooth
- **Warm-up Period**: 60-minute initial warm-up
- **Apple Health Integration**: Sends interstitial fluid glucose data to HealthKit
- **Follow Mode Compatibility**: Technically feasible with Follower Mode approach

### Implementation Approach: Follower Mode

**Key Principle**: ViiRaa will implement Follower Mode, NOT Master Mode (direct BLE connection).

**Follower Mode Characteristics:**

- Monitors communication between official Abbott Lingo app and sensor
- Extracts glucose readings without breaking encryption
- Requires users to install and run official Abbott Lingo app alongside ViiRaa
- Does NOT reverse-engineer proprietary protocols
- Legally compliant with manufacturer Terms of Service
- App Store compliant (similar approach to xDrip4iOS)

**Advantages:**

- ✅ No legal risk (does not violate DMCA or manufacturer ToS)
- ✅ App Store compliant
- ✅ Updates to official apps don't break functionality
- ✅ Maintains manufacturer's security and safety guarantees

**Disadvantages:**

- ❌ Requires users to install two apps (official Abbott Lingo app + ViiRaa)
- ❌ Limited by official app's data update frequency
- ❌ Depends on Abbott Lingo app remaining functional
- ❌ Increased user onboarding complexity

### Hybrid Architecture Strategy

**Recommended Approach**: Use both Junction SDK AND BLE Follow Mode in parallel

Junction API Key is stored in `/Users/barack/Downloads/Xcode/Credentials.md`

```
┌─────────────────────────────────────────────────────┐
│              ViiRaa iOS App                         │
├─────────────────────────────────────────────────────┤
│                                                     │
│  ┌───────────────────┐   ┌────────────────────┐   │
│  │  Junction SDK     │   │  BLE Follow Mode   │   │
│  │  (via HealthKit)  │   │  (Abbott Lingo)    │   │
│  ├───────────────────┤   ├────────────────────┤   │
│  │ Latency: 3 hours  │   │ Latency: 1-5 min   │   │
│  │ Use: ML training  │   │ Use: Real-time UI  │   │
│  │ Status: Primary   │   │ Status: Optional   │   │
│  └───────────────────┘   └────────────────────┘   │
│           │                       │                │
│           └───────┬───────────────┘                │
│                   ▼                                │
│         ┌──────────────────┐                       │
│         │  Data Validator  │                       │
│         │  Cross-validate  │                       │
│         │  both sources    │                       │
│         └──────────────────┘                       │
└─────────────────────────────────────────────────────┘
```

**Data Pipeline Roles:**

1. **Junction SDK (Primary)**

   - Historical data collection for ML model training
   - HIPAA-compliant cloud storage
   - Long-term data retention
   - Fallback when BLE unavailable
   - Works with all 300+ supported devices
2. **BLE Follow Mode (Real-time)**

   - Low-latency glucose readings for user-facing UI
   - Real-time alerts and notifications
   - Immediate user feedback
   - Enhanced user experience
   - Cross-validation against Junction data

### Implementation Phases

**Phase 2 (Week 2-4): Foundation**

- Deploy Junction SDK with HealthKit integration
- Collect user feedback on 3-hour data delay
- Assess impact on product/science goals
- **Decision Point**: Go/No-go for BLE Follow Mode

**Phase 3 (Week 7-12): BLE Follow Mode (Only if latency is blocker)**

- Research xDrip4iOS implementation approach
- Develop Follower Mode data interceptor
- Implement for Abbott Lingo (1-5 minute latency)
- Build user onboarding flow for dual-app setup
- Create settings UI for BLE configuration
- Test via TestFlight before App Store submission
- Deploy with feature flag for gradual rollout

### Legal & Compliance Considerations

**Approved Approach (Follower Mode):**

- ✅ No reverse engineering of proprietary protocols
- ✅ No decryption of manufacturer encryption
- ✅ Does not violate DMCA
- ✅ Complies with manufacturer Terms of Service
- ✅ App Store compliant (xDrip4iOS precedent)

**Prohibited Approach (Master Mode):**

- ❌ Direct BLE connection to CGM sensor (bypassing official app)
- ❌ Reverse engineering encryption protocols
- ❌ Breaking device authorization mechanisms
- ❌ High legal risk and App Store rejection risk

### User Experience Flow (BLE Follow Mode)

**User Onboarding:**

1. User downloads ViiRaa app from App Store
2. User completes standard authentication flow
3. App detects if user wants real-time glucose monitoring
4. If yes, app guides user to install official Abbott Lingo app
5. User pairs CGM sensor with official Abbott Lingo app first
6. User enables BLE Follow Mode in ViiRaa settings
7. ViiRaa monitors official app communications
8. Real-time glucose data appears in ViiRaa dashboard

**Settings UI Requirements:**

- Toggle to enable/disable BLE Follow Mode
- Status indicator (connected/disconnected)
- Instructions for troubleshooting
- Link to official CGM app download
- Clear explanation of dual-app requirement
- Fallback messaging if BLE unavailable

### Cost-Benefit Analysis

| Factor                 | Junction SDK Only | Junction + BLE Follow Mode |
| ---------------------- | ----------------- | -------------------------- |
| Development Time       | 1-2 weeks         | 3-4 months                 |
| Maintenance Complexity | Low               | Medium                     |
| Legal Risk             | None              | Low                        |
| Data Latency           | 3 hours           | 1-5 minutes                |
| User Setup Complexity  | Low (1 app)       | Medium (2 apps)            |
| ML Training Capability | Excellent         | Excellent                  |
| Real-time Alerts       | Limited           | Good                       |
| Device Compatibility   | 300+ devices      | Abbott Lingo only          |

### Success Metrics (Phase 3)

**Technical Metrics:**

- BLE data latency: <5 minutes average
- Data accuracy: >95% match with official Abbott Lingo app readings
- Cross-validation success rate: >98%
- Fallback to Junction: <5% of sessions

**User Metrics:**

- Dual-app setup completion rate: >60%
- BLE Follow Mode adoption rate: >30% of eligible users
- User satisfaction with real-time data: 4.0+ rating

**Business Metrics:**

- Reduced churn due to real-time insights
- Increased engagement with real-time alerts
- Improved ML model accuracy with higher-frequency data

### References

- xDrip4iOS Documentation: https://xdrip4ios.readthedocs.io/
- Third-Party Bio Data Integration Report: `/Users/barack/Downloads/Xcode/3rd_Party_Bio_Data_Integration_Report.md`
- Abbott Lingo Technical Specifications (Section 2.3)
- BLE Implementation Recommendations (Section 2.5)

---

## 13. Appendix

### Related Documents

- Software Design Document (SD) - To be created
- ViiRaa Web Dashboard Source Code: `/viiraalanding-main`
- Third-Party Bio Data Integration Report: `/Users/barack/Downloads/Xcode/3rd_Party_Bio_Data_Integration_Report.md`

### References

- ViiRaa existing tech stack: React 18, TypeScript, Supabase, Stripe
- Dashboard URL: `/dashboard` route from web app
- Authentication: Supabase Auth with Google OAuth + Email/Password

### Glossary

- **WebView**: Native component that renders web content within mobile apps
- **WKWebView**: Apple's modern WebView implementation for iOS
- **MVP**: Minimum Viable Product
- **Bootcamp**: ViiRaa's user program for glucose monitoring
- **Mattermost**: Open-source messaging platform alternative to Telegram
