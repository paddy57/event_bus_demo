import 'dart:async';
import 'dart:developer';

import 'package:event_bus/event_bus.dart';
import 'package:event_bus_demo/event_bus.dart';
import 'package:flutter/material.dart';

/// Enum defining the sequence of popups to be shown
/// Popups should show in this sequence: A, B, C, D
enum ListPopupEnum {
  popupA,
  popupB,
  popupC,
  popupD,
}

/// Utility class for managing sequential popup display using event bus pattern
/// This class handles the logic for showing popups in a specific order (A, B, C, D)
/// and manages the event-driven flow between popups
class PopupUtils {
  /// Constructor that sets up event bus listener
  /// Listens to all events and processes them through the event queue
  PopupUtils() {
    locator<EventBus>().on<Event>().listen(onBusEvent);
  }

  /// Complete list of all popup types in sequence order
  List<ListPopupEnum> sequenceList = ListPopupEnum.values;

  /// List of popups that are available to show (filtered based on conditions)
  List<ListPopupEnum> availablePopupList = [];

  /// Index tracking which popup we're currently checking for availability
  int activePopupIndex = 0;

  /// Index tracking which popup we're currently showing from available list
  int currentShownPopupIndex = 0;

  /// Initializes the popup sequence by emitting the initial events
  /// This triggers the event bus to start processing popups
  Future<void> initialCall(BuildContext context) async {
    ShowPopup(context).emit();
    ExitPopup(context).emit();
  }

  /// Queue to store events that need to be processed sequentially
  List<Event> eventQueue = [];

  /// Flag to prevent concurrent event processing
  bool isProcessing = false;

  /// Processes events from the queue sequentially
  /// This ensures popups are shown in the correct order and prevents race conditions
  Future<void> processEventQueue() async {
    if (isProcessing) return; // Prevent concurrent processing
    isProcessing = true;

    // Process all events in the queue one by one
    while (eventQueue.isNotEmpty) {
      final event = eventQueue.removeAt(0);

      // Handle ShowPopup event - checks which popups are available
      if (event is ShowPopup) {
        await handlePopupShown(event);
      }

      // Handle ExitPopup event - shows the next available popup
      if (event is ExitPopup) {
        await handlePopupOver(event);
      }
    }
    isProcessing = false;
  }

  /// Handles ShowPopup event by checking which popups are available to show
  /// This method filters the sequence list to only include available popups
  Future<void> handlePopupShown(ShowPopup event) async {
    bool nextFound = false;

    // Loop through sequence until we find the first available popup
    while (!nextFound && activePopupIndex < sequenceList.length) {
      ListPopupEnum currentPopupEnum = sequenceList[activePopupIndex];

      // Check if this popup is available to show
      bool isPopupAvailable =
          await isPopUpAvailableToShow(currentPopupEnum, event.context);

      if (isPopupAvailable) {
        nextFound = true;
        availablePopupList.add(currentPopupEnum);
      }

      activePopupIndex++; // Move to next popup in sequence
      log('===> popup available to show list $availablePopupList');
    }
  }

  /// Handles ExitPopup event by showing the next available popup
  /// This method is called when a popup is dismissed and we need to show the next one
  Future<void> handlePopupOver(ExitPopup event) async {
    // Check if we have more popups to show
    if (currentShownPopupIndex < availablePopupList.length) {
      ListPopupEnum currentAvailablePopupEnum =
          availablePopupList[currentShownPopupIndex];
      showPopUp(currentAvailablePopupEnum, event.context);
      currentShownPopupIndex++; // Move to next popup
    } else {
      log('===> No more popups to show. Sequence completed.');
    }
  }

  /// Event bus listener that receives all events and adds them to the queue
  /// This is the entry point for all events in the popup system
  Future<void> onBusEvent(Event event) async {
    eventQueue.add(event);
    processEventQueue();
  }

  /// Determines if a specific popup is available to show
  /// This method can be customized to check various conditions like:
  /// - User permissions
  /// - App state
  /// - Previous user actions
  /// - Feature flags
  ///
  /// For demo purposes, static values are used, but in real apps,
  /// you would check actual conditions here
  Future<bool> isPopUpAvailableToShow(
      ListPopupEnum value, BuildContext context) async {
    switch (value) {
      case ListPopupEnum.popupA:
        return true; // Always available
      case ListPopupEnum.popupB:
        return false; // Not available (demo: user hasn't completed prerequisite)
      case ListPopupEnum.popupC:
        return true; // Always available
      case ListPopupEnum.popupD:
        return false; // Not available (demo: feature not enabled)
      default:
        return false;
    }
  }

  /// Main method to display a specific popup based on the enum value
  /// This method routes to the appropriate popup implementation
  Future<void> showPopUp(ListPopupEnum value, BuildContext context) async {
    switch (value) {
      case ListPopupEnum.popupA:
        log('===> show : popupA');
        await _showPopupA(context);
        break;
      case ListPopupEnum.popupB:
        log('===> show : popupB');
        await _showPopupB(context);
        break;
      case ListPopupEnum.popupC:
        log('===> show : popupC');
        await _showPopupC(context);
        break;
      case ListPopupEnum.popupD:
        log('===> show : popupD');
        await _showPopupD(context);
        break;
      default:
        break;
    }
  }

  /// Popup A - Simple Alert Dialog
  /// A basic alert dialog with a single OK button
  /// This demonstrates the simplest popup pattern
  Future<void> _showPopupA(BuildContext context) async {
    ShowPopup(context).emit(); // Emit event to track popup shown
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // Prevent dismissing by tapping outside
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Popup A'),
          content: const Text('This is Popup A - A simple alert dialog.'),
          actions: <Widget>[
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
                ExitPopup(context).emit(); // Emit event to continue sequence
              },
            ),
          ],
        );
      },
    );
  }

  /// Popup B - Confirmation Dialog
  /// A dialog with two options (Cancel/Confirm) and an icon
  /// This demonstrates a confirmation pattern commonly used in apps
  Future<void> _showPopupB(BuildContext context) async {
    ShowPopup(context).emit(); // Emit event to track popup shown
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // Prevent dismissing by tapping outside
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.question_mark, color: Colors.blue),
              SizedBox(width: 8),
              Text('Popup B'),
            ],
          ),
          content: const Text(
              'This is Popup B - A confirmation dialog with two options.'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
                ExitPopup(context).emit(); // Emit event to continue sequence
              },
            ),
            ElevatedButton(
              child: const Text('Confirm'),
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
                ExitPopup(context).emit(); // Emit event to continue sequence
              },
            ),
          ],
        );
      },
    );
  }

  /// Popup C - Custom Dialog with Content
  /// A custom dialog with icon, styled content, and multiple action buttons
  /// This demonstrates a more complex popup pattern with custom styling
  Future<void> _showPopupC(BuildContext context) async {
    ShowPopup(context).emit(); // Emit event to track popup shown
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // Prevent dismissing by tapping outside
      builder: (BuildContext context) {
        return Dialog(
          child: Container(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Large star icon for visual appeal
                const Icon(
                  Icons.star,
                  size: 64,
                  color: Colors.amber,
                ),
                const SizedBox(height: 16),
                // Styled title
                const Text(
                  'Popup C',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                // Description text
                const Text(
                  'This is Popup C - A custom dialog with icon and styled content.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                // Action buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    TextButton(
                      child: const Text('Skip'),
                      onPressed: () {
                        Navigator.of(context).pop(); // Close the dialog
                        ExitPopup(context)
                            .emit(); // Emit event to continue sequence
                      },
                    ),
                    ElevatedButton(
                      child: const Text('Continue'),
                      onPressed: () {
                        Navigator.of(context).pop(); // Close the dialog
                        ExitPopup(context)
                            .emit(); // Emit event to continue sequence
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Popup D - Styled Dialog with Success Message
  /// A dialog with rounded corners, success styling, and informational content
  /// This demonstrates a completion/success popup pattern
  Future<void> _showPopupD(BuildContext context) async {
    ShowPopup(context).emit(); // Emit event to track popup shown
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // Prevent dismissing by tapping outside
      builder: (BuildContext context) {
        return AlertDialog(
          // Custom shape with rounded corners
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Row(
            children: [
              Icon(Icons.info_outline, color: Colors.green),
              SizedBox(width: 8),
              Text('Popup D'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                  'This is Popup D - A styled dialog with rounded corners.'),
              const SizedBox(height: 16),
              // Success message container with custom styling
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.green, size: 20),
                    SizedBox(width: 8),
                    Text('Feature completed successfully!'),
                  ],
                ),
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Close'),
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
                ExitPopup(context).emit(); // Emit event to continue sequence
              },
            ),
          ],
        );
      },
    );
  }
}
