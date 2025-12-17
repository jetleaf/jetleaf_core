// ---------------------------------------------------------------------------
// 🍃 JetLeaf Framework - https://jetleaf.hapnium.com
//
// Copyright © 2025 Hapnium & JetLeaf Contributors. All rights reserved.
//
// This source file is part of the JetLeaf Framework and is protected
// under copyright law. You may not copy, modify, or distribute this file
// except in compliance with the JetLeaf license.
//
// For licensing terms, see the LICENSE file in the root of this project.
// ---------------------------------------------------------------------------
// 
// 🔧 Powered by Hapnium — the Dart backend engine 🍃

library;

export 'src/availability/application_availability.dart';
export 'src/availability/application_availability_auto_configuration.dart';
export 'src/availability/availability_event.dart';
export 'src/availability/availability_state.dart';

export 'src/context/condition/condition.dart';
export 'src/context/condition/conditions.dart';
export 'src/context/condition/condition_evaluator.dart';

export 'src/diagnostics/application_diagnostics.dart' hide ExceptionDiagnosticsManager;
export 'src/diagnostics/abstract_exception_diagnoser.dart';
export 'src/diagnostics/exception_diagnoser.dart';
export 'src/diagnostics/exception_reporter.dart';
export 'src/diagnostics/loggable_exception_diagnosis_reporter.dart';

export 'src/scope/annotated_scope_metadata_resolver.dart';
export 'src/scope/scope_metadata_resolver.dart';

export 'src/startup/startup_event.dart';

export 'src/aware.dart';
export 'src/exceptions.dart';
export 'src/resource.dart';
export 'src/to_json_factory.dart';
export 'src/annotation_aware_order_comparator.dart';