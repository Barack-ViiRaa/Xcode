# fProduct Requirements Document: ViiRaa iOS App

## Document Information

- **Version**: 2.1
- **Last Updated**: 2025-10-20
- **Product**: ViiRaa iOS Mobile Application
- **Status**: Updated with Manager Feedback

## Executive Summary

ViiRaa will launch a native iOS application to provide users with a seamless mobile experience. The app follows a pragmatic two-phase strategy:

**Phase 1 (Week 1)**: Deploy a WebView-based MVP to TestFlight for internal team validation, bypassing App Store approval requirements. This enables rapid development (3-5 days) and immediate feedback.

**Phase 2 (Week 2-4)**: Add Apple HealthKit integration to strengthen the App Store approval case by demonstrating native iOS functionality beyond web content. HealthKit will enable reading CGM data, weight tracking, and activity metrics—capabilities that justify the app's existence as a native iOS experience.

This strategy addresses the critical user acquisition gap where potential users instinctively search for a mobile app rather than visiting the website, while mitigating the high risk of App Store rejection for WebView-only applications.

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
  - **Chat Tab**: Placeholder UI (preparation for Phase 2)
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
- Android app development (keep cross-platform considerations in mind during iOS development)

**Nice-to-have (Post-MVP):**

- iPad optimization (while MVP supports iPad, UI optimization deferred)
- Fully native UI components (replacing WebView gradually)
- Offline functionality
- Apple Watch integration
- Widget support
- Advanced iOS-specific features

### Phase 2: Chat Integration (Future)

#### 5.1 In Scope

- Integration of miniViiRaa (AI coach) chat functionality into iOS app
- **Preferred Approach**: WebView-based chat interface
  - Enables web access to miniViiRaa in mid-term roadmap
  - Maintains code reusability across platforms
  - Faster iteration and deployment
- Evaluation and implementation of Mattermost (open-source alternative to Telegram)
- Real-time messaging capabilities
- Migration path from existing Telegram dependency

#### 5.2 Timeline

- Start: After Phase 1 (Dashboard) is complete and deployed
- Goal: Consolidate all user interactions within native app

#### 5.3 Rationale

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

1. User authenticates via iOS native login screen (Google OAuth or email/password)
2. iOS app receives full Supabase session (access_token, refresh_token, user data)
3. Session is securely stored in iOS Keychain
4. When loading web dashboard in WebView:
   - iOS app injects complete Supabase session into WebView's localStorage
   - Session is injected before page load (via WKUserScript) and after page load (via evaluateJavaScript)
   - Web dashboard's Supabase client reads session from localStorage
   - User is automatically authenticated in web dashboard - **no second login required**
5. Web dashboard recognizes existing session and displays authenticated content
6. User has seamless single sign-on experience across iOS and web

### Key Screens

1. **Splash Screen**: ViiRaa branding
2. **Authentication Screen**: Login/signup options
3. **Dashboard Tab**: WebView with user dashboard
4. **Chat Tab**: Placeholder (Phase 1) → Chat interface (Phase 2)
5. **Settings/Profile**: Native settings screen (future enhancement)

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
7. 🔲 Internal demo with team
8. 🔲 TestFlight deployment for internal testing

**Phase 2: App Store Preparation (Week 2-4)**
9. 🔲 Apple HealthKit integration (CRITICAL for approval)

- CGM data reading capability
- Weight tracking read capability
- Activity/fitness data read capability

10. 🔲 Enhanced native features to strengthen approval case
11. 🔲 Marketing materials preparation (aligned with landing page updates)
12. 🔲 App Store submission
13. 🔲 App Store approval and public launch

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

| Risk                                                  | Impact             | Probability    | Mitigation                                                                                                                                                                                                             |
| ----------------------------------------------------- | ------------------ | -------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **App Store rejection due to WebView-only app** | **Critical** | **High** | **Two-phase approach: (1) TestFlight for internal validation bypasses App Store review, (2) Add Apple HealthKit integration before public submission to strengthen approval case with native iOS functionality** |
| WebView performance issues                            | Medium             | Low            | Optimize web dashboard for mobile, implement loading states                                                                                                                                                            |
| Authentication complexity                             | Medium             | Medium         | Use existing Supabase mobile SDKs, thorough testing                                                                                                                                                                    |
| Web dashboard not mobile-friendly                     | High               | Low            | Verify responsive design, make CSS adjustments if needed                                                                                                                                                               |
| Delayed timeline for HealthKit integration            | Medium             | Medium         | Prioritize TestFlight launch first, add HealthKit in parallel for App Store submission                                                                                                                                 |
| Android platform fragmentation when expanding         | Medium             | Low            | Design with cross-platform in mind from start; WebView approach supports this strategy                                                                                                                                 |

---

## 10. Success Criteria

### TestFlight MVP Launch Criteria (Week 1)

- [ ] TestFlight build successfully deployed for internal testing
- [ ] Users can authenticate using existing credentials
- [ ] Dashboard loads and functions correctly in WebView
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
- [ ] App successfully submitted and approved on App Store
- [ ] Marketing materials prepared (aligned with landing page updates)
- [X] Native iOS features beyond WebView demonstrate value for approval

### Phase 2 Success Criteria (Chat & Engagement)

- [ ] miniViiRaa (AI coach) chat functionality integrated via WebView
- [ ] Mattermost or alternative chat backend evaluated and implemented
- [ ] Users can send and receive messages within app
- [ ] Migration from Telegram completed
- [ ] Push notifications implemented for engagement and coaching reminders
- [ ] Web-based AI coach access enabled for cross-platform consistency

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

---

## 12. Appendix

### Related Documents

- Software Design Document (SD) - To be created
- ViiRaa Web Dashboard Source Code: `/viiraalanding-main`

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
