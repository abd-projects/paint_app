# Paint App

A drawing and painting application built with **Flutter and Dart**, inspired by MS Paint. The app provides a canvas for freehand drawing, multiple brush styles, color selection, and text editing, with support for additional image editing features as development progresses.

## Features

### Drawing Tools
- **Normal Brush** – Draw freehand strokes on the canvas.
- **Pencil** – Draw with thinner strokes.
- **Marker** – Draw with semi-transparent, thicker strokes.
- **Highlighter** – Create broad, translucent strokes.
- **Spray Brush** – Simulate spray painting using randomly distributed dots.
- **Eraser** – Remove existing marks by painting over them.

### Color Picker
- Select from a collection of predefined colors.
- Choose custom colors using a hue slider and color selection square.
- Adjust color opacity.
- Enter custom Alpha, Red, Green, and Blue values.
- Use the eyedropper to pick colors directly from the canvas.

### Text Tool
- Enter text through a dialog.
- Choose from available font options.
- Preview text before adding it to the canvas.
- Move and resize text before confirming its placement.

### Canvas Controls
- Adjust brush size using predefined or custom values.
- Undo the most recent canvas operation.
- Redo previously undone operations.
- Clear the canvas.

### Image Import and Export
Image import and export are planned features for integrating external images into the drawing canvas and saving finished artwork to the device gallery.

## Technologies Used

- **Flutter** – Cross-platform UI framework.
- **Dart** – Programming language.
- **CustomPainter** – Renders strokes, text, and other canvas objects.
- **GestureDetector** – Handles drawing gestures and object manipulation.
- **Material Design** – Provides the application interface.

## Project Structure

The application uses an object-based canvas design.

- `CanvasObject` – Base class for objects displayed on the canvas.
- `BrushStroke` – Stores drawing points and brush information.
- `DrawingPoint` – Stores a point's position, brush size, color, and spray particles.
- `TextObject` – Stores text content, position, font size, font family, and color.
- `MyPainter` – Renders canvas objects using Flutter's `CustomPainter`.
- `PaintPageState` – Manages application state, drawing interactions, tools, and canvas operations.

This structure allows different types of objects to be rendered and managed on a shared canvas.

## Getting Started

### Prerequisites

Install the following:

- [Flutter SDK](https://docs.flutter.dev/get-started/install)
- [Dart SDK](https://dart.dev/get-dart)
- Android Studio, VS Code, or another Flutter-compatible IDE
- An Android emulator or a physical device

### Installation

1. Clone the repository:

   ```bash
   git clone <repository-url>
   ```

2. Navigate to the project directory:

   ```bash
   cd <project-directory>
   ```

3. Install dependencies:

   ```bash
   flutter pub get
   ```

4. Run the application:

   ```bash
   flutter run
   ```

## How to Use

1. Launch the application.
2. Select a color using the color picker.
3. Choose a brush style from the brush menu.
4. Adjust the brush size as required.
5. Draw on the canvas using touch or pointer gestures.
6. Use undo and redo to manage canvas changes.
7. Select the text tool to enter text and configure its appearance.
8. Confirm text placement when satisfied.

## Future Improvements

- Import images from the device gallery.
- Move and resize imported images before confirming placement.
- Export artwork as PNG images.
- Improve text selection, movement, and resizing.
- Add geometric drawing tools such as lines, rectangles, circles, and arrows.
- Improve canvas navigation and object selection.
- Add support for saving and reopening projects.

## Objectives

This project explores Flutter application development through practical implementation of:

- Stateful UI and event handling.
- Custom drawing with `Canvas` and `CustomPainter`.
- Object-oriented programming and inheritance.
- Gesture-based interactions.
- Color manipulation using HSV and ARGB representations.
- Managing collections of drawable objects.
- Undo and redo functionality.

## Screenshots

<img width="343" height="690" alt="image" src="https://github.com/user-attachments/assets/18989074-103c-40e9-a460-0849cf4c369f" />
<img width="338" height="552" alt="image" src="https://github.com/user-attachments/assets/de3c86ec-f287-46d2-86eb-97b4b3c6ee54" />
<img width="359" height="674" alt="image" src="https://github.com/user-attachments/assets/2ba4d095-e163-43cd-ac01-36e17cac51cc" />
