import 'dart:developer';

import 'package:event_bus/event_bus.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

GetIt get locator => GetIt.instance;

//setting up of event bus

void setUpEventBus() {
  if (!locator.isRegistered<EventBus>()) {
    locator.registerSingleton(EventBus());
    log('EventBus registered');
  } else {
    log('EventBus is already registered');
  }
}

//to fire event
mixin EventEmitter {
  Future<void> emit() async {
    final eventBus = locator<EventBus>();
    eventBus.fire(this);
  }
}

abstract class Event with EventEmitter {}

//creating two events

class ExitPopup extends Event {
  final BuildContext context;
  ExitPopup(this.context);
}

class ShowPopup extends Event {
  final BuildContext context;
  ShowPopup(this.context);
}
