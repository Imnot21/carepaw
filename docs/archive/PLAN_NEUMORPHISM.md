# Neumorphism Design Overhaul Plan

## Goal
Overhaul the CarePaw frontend using neumorphism, organic, and minimalistic design language.

## Steps

### 1. Update Color Palette (`lib/app/theme/app_colors.dart`)
- Change background to warm off-white: `#FFF8F5F0` (light) and `#1A1A1A` (dark)
- Update surface colors: `#FFFFFFFF` (light surface) and `#2A2A2A` (dark surface)
- Define new primary color (organic terracotta): `#FFE27D60`
- Define new accent color (sage green): `#FF8FBC8F`
- Update shadow colors for soft, organic depth:
  - Light mode: highlight `#FFFFFF`, shadow `#D9D9D9`
  - Dark mode: highlight `#E0E0E0`, shadow `#555555`
- Update text colors for better readability:
  - Light mode: primary `#111111`, secondary `#2B2B2B`, tertiary `#4A4A4A`
  - Dark mode: primary `#FFFFFF`, secondary `#E5E7EB`, tertiary `#D1D5DB`
- Keep status colors (error, success, warning) but ensure they harmonize with new palette
- Maintain pet-themed accents with slight adjustments for warmth if needed

### 2. Update Shadow System (`lib/core/widgets/neomorphism/neu_shadows.dart`)
- Modify `_light()` and `_dark()` methods to return new shadow colors
- Adjust shadow opacity, blur radius, and offset for softer, more organic feel
- Ensure raised, pressed, flat, and inset shadows use the new color definitions
- Maintain the dual-shadow approach (light from top-left, depth from bottom-right)

### 3. Refine Base Neumorphic Container (`lib/core/widgets/neomorphism/neu_container.dart`)
- Increase default borderRadius from 20 to 24 for more rounded, organic feel
- Add default padding: `EdgeInsets.symmetric(horizontal: 16, vertical: 12)` for better spacing
- Ensure the container uses the updated color and shadow systems
- Verify that all variants (raised, pressed, inset, flat, transparent) work with new tokens

### 4. Update Neumorphic Button (`lib/core/widgets/neomorphism/neu_button.dart`)
- Use new primary color (`AppColors.primary`) for filled buttons
- Use new primaryLight for outlined buttons foreground
- Use new shadow colors for button shadows
- Maintain the same shape and padding but with updated colors
- Ensure both outlined and filled variants work with the new design tokens

### 5. Create Additional Neumorphic Widgets (as needed)
- **NeuTextField**: A text field that uses NeuContainer with appropriate styling
- **NeuCard**: A card widget based on NeuContainer for consistent elevation
- **NeuAvatar**: A circular avatar with tinted background using pet-themed accents
- Ensure all new widgets follow the same design tokens and shadow system

### 6. Pilot Screen Migration (`lib/features/authentication/presentation/pages/login_page.dart`)
- Convert the login page to use the new NeuContainer, NeuButton, and NeuTextField
- Apply the new color palette throughout the screen
- Ensure spacing and typography align with minimalistic principles
- Validate that the design feels organic, soft, and trustworthy

### 7. Progressive Rollout
- Migrate home page and dashboard screens (admin, vet, staff) next
- Convert pet management, appointments, queue, medical records, inventory, and scanning screens
- Update navigation and bottom bars to use the new design
- Ensure consistency across all screens

### 8. Accessibility and Contrast Audit
- Run accessibility contrast checks on all color combinations
- Adjust colors as needed to meet WCAG AA standards for text and UI elements
- Ensure that the organic colors still provide sufficient contrast for readability

### 9. Documentation
- Add a README in `lib/core/widgets/neomorphism/` explaining the design system
- Document usage of NeuContainer, NeuButton, NeuTextField, etc.
- Include examples and best practices for maintaining the neumorphic language

## Expected Outcome
A fresh, modern frontend that feels warm, trustworthy, and easy to use—aligning with the organic and minimalistic neumorphism design language while maintaining the core functionality of the CarePaw veterinary patient management system.