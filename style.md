# Style Guide - LaChispa

## Color Palette

### Main Colors
- **Main Background**: Linear diagonal gradient (topLeft → bottomRight)
  - `Color(0xFF0F1419)` - Deep dark blue
  - `Color(0xFF1A1D47)` - Medium blue
  - `Color(0xFF2D3FE7)` - Vibrant blue
  - Stops: `[0.0, 0.5, 1.0]`

### Accent Colors
- **Primary Blue**: `Color(0xFF2D3FE7)` 
- **Secondary Blue**: `Color(0xFF4C63F7)`
- **Bright Blue**: `Color(0xFF5B73FF)` (used in particles)

### Text Colors
- **Primary Text**: `Colors.white`
- **Secondary Text**: `Colors.white` with 0.9 opacity
- **Tertiary Text**: `Colors.white` with 0.6-0.8 opacity
- **Placeholder**: `Colors.white` with 0.4 opacity

## Typography

### Main Font
- **Family**: `Inter`
- **Main Titles**: 
  - Size: 48px
  - Weight: FontWeight.bold
  - Color: Colors.white
- **Subtitles**: 
  - Size: 18px
  - Weight: FontWeight.w500
  - Color: Colors.white with 0.9 opacity
- **Body Text**: 
  - Size: 16px
  - Weight: FontWeight.w500
  - Color: Colors.white with 0.9 opacity
- **Button Text**: 
  - Size: 16px
  - Weight: FontWeight.w600
  - Color: Colors.white

## UI Components

### Glassmorphism Cards
- **Background**: `Colors.white` with 0.08 opacity
- **Border**: `Colors.white` with 0.1 opacity, 1px width
- **Border Radius**: 16px
- **Shadow**: `Colors.black` with 0.1 opacity, blur 10px, offset (0, 4)

### Primary Buttons
- **Background**: Linear gradient (centerLeft → centerRight)
  - `Color(0xFF2D3FE7)` → `Color(0xFF4C63F7)`
- **Border Radius**: 16px
- **Height**: 56px
- **Shadow**: `Color(0xFF2D3FE7)` with 0.3 opacity, blur 12px, offset (0, 6)
- **Text**: Colors.white, Inter, 16px, FontWeight.w600

### Secondary Buttons (Glass)
- **Background**: `Colors.white` with 0.08 opacity
- **Border**: `Colors.white` with 0.1 opacity, 1px width
- **Border Radius**: 16px
- **Height**: 56px
- **Shadow**: `Colors.black` with 0.1 opacity, blur 10px, offset (0, 4)
- **Text**: Colors.white, Inter, 16px, FontWeight.w500

### Text Fields
- **Background**: `Colors.white` with 0.08 opacity
- **Border**: `Colors.white` with 0.1 opacity, 1px width
- **Border Radius**: 16px
- **Padding**: 24px horizontal, 22px vertical
- **Icons**: `Colors.white` with 0.6 opacity, size 20px
- **Text**: Colors.white, 16px
- **Placeholder**: `Colors.white` with 0.4 opacity

### Navigation Buttons
- **Background**: `Colors.white` with 0.08 opacity
- **Border**: `Colors.white` with 0.1 opacity, 1px width
- **Border Radius**: 12px
- **Size**: 48x48px
- **Icon**: Colors.white, size 24px

## Spark Effect

### Technical Specifications
- **Frequency**: Every 3 seconds exactly
- **Quantity per cycle**: 2-4 sparks per screen
- **Particles per spark**: 10-30 particles
- **Position**: Random across entire screen
- **Lifespan**: 100 frames with degradation

### Particle Properties
- **Size**: 1-4px (random)
- **Speed**: Organic radial distribution (2-6 intensity)
- **Deceleration**: 0.99 per frame
- **Opacity**: EaseOutQuart curve for smooth fade
- **Colors**:
  - Outer glow: `Color(0xFF5B73FF)` with 0.4 opacity
  - Inner glow: `Color(0xFF4C63F7)` with 0.8 opacity
  - Central particle: `Color(0xFF5B73FF)` with 0.9 opacity

### Rendering Layers
1. **Outer glow**: 2x radius, blur 2.0
2. **Inner glow**: 1.5x radius, blur 2.0
3. **Solid particle**: 1x radius, no blur

### Implementation
- **AnimationController**: 16ms (60 FPS)
- **Timer**: 3-second intervals
- **CustomPainter**: SparkPainter with automatic updates
- **Optimization**: Automatic removal of dead particles

## Animations

### Entrance Animations (Staggered)
- **Total Duration**: 1600-2000ms
- **Curve**: Curves.easeOutCubic
- **Staggered Intervals**:
  - Header: 0.0-0.4 (immediate)
  - Content: 0.3-0.7 (overlapping)
  - Footer: 0.6-1.0 (final)
- **Offset**: 30-50px from bottom
- **Opacity**: 0.0 → 1.0

### Glow Animations
- **Duration**: 2000ms
- **Repeat**: reverse: true (ping-pong)
- **Curve**: Curves.easeInOut
- **Range**: 0.3 → 1.0
- **Application**: Title shadows

## Spacing and Layout

### Standard Spacing
- **Horizontal padding**: 24px
- **Element spacing**: 16-24px
- **Large spacing**: 32-48px
- **Bottom margin**: 32px

### Responsive Design
- **Mobile breakpoint**: < 600px
- **Mobile layout**: Vertical column
- **Tablet layout**: Horizontal row for buttons
- **Flex**: Spacer(flex: 2) for vertical centering

## Reusable Components

### Particle System
- **Class**: `Particle` with physical properties
- **Generator**: `_createRandomSpark()` with random distribution
- **Painter**: `SparkPainter` with optimized rendering
- **Timer**: `_setupSparkTimer()` for regular cycles

### Glassmorphism Pattern
- Consistently applied to:
  - Feature cards
  - Secondary buttons
  - Input fields
  - Navigation elements

## Design Patterns

### Visual Consistency
- **Same background gradient** across all screens
- **Same particle system** as animated background
- **Same proportions** for similar elements
- **Same typography** Inter for all text

### Visual Hierarchy
- **Main titles**: Larger size, bold weight
- **Subtitles**: Medium size, medium weight
- **Body text**: Base size, normal weight
- **Secondary text**: Reduced opacity for less prominence

### Interactivity
- **Hover states**: Implicit in ElevatedButton
- **Loading states**: White CircularProgressIndicator
- **Visual feedback**: Navigation with transition animations
- **Accessibility**: White contrast on dark background

## Technical Implementation

### Animation Structure
```dart
late AnimationController _staggerController;
late AnimationController _sparkController;
late Animation<double> _titleAnimation;
// ... more animations
```

### Gradient Configuration
```dart
decoration: BoxDecoration(
  gradient: LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF0F1419),
      Color(0xFF1A1D47),
      Color(0xFF2D3FE7),
    ],
    stops: [0.0, 0.5, 1.0],
  ),
)
```

### Glassmorphism Configuration
```dart
decoration: BoxDecoration(
  color: Colors.white.withValues(alpha: 0.08),
  borderRadius: BorderRadius.circular(16),
  border: Border.all(
    color: Colors.white.withValues(alpha: 0.1),
    width: 1,
  ),
  boxShadow: [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.1),
      blurRadius: 10,
      offset: Offset(0, 4),
    ),
  ],
)
```

## Implementation Notes

### Compatibility
- **Flutter 3.x**: Uses `withValues(alpha: x)` instead of `withOpacity(x)`
- **60 FPS**: AnimationController with 16ms for smoothness
- **Performance**: Automatic particle removal to prevent memory leaks
- **Responsiveness**: LayoutBuilder for adaptation to different sizes

### Quality Standards
- **Smooth animations**: EaseOutCubic curves for naturalness
- **Consistent colors**: Limited and coherent palette
- **Clear typography**: Inter for optimal readability
- **Proportional spacing**: 8px multiples for consistent grid

This style should be maintained consistently across all future screens and components of the Chispa application.