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

// import 'package:jetleaf_convert/src/core/conversion_service.dart';
// import 'package:jetleaf_lang/src/meta/class.dart';
// import 'package:jetleaf_pod/pod.dart';

// class MockPodFactory implements ConfigurableListablePodFactory {
//   final Map<String, Object> _singletons = {};
  
//   @override
//   void removeSingleton(String name) {
//     _singletons.remove(name);
//   }
  
//   void addSingleton(String name, Object instance) {
//     _singletons[name] = instance;
//   }
  
//   // Other required methods with default implementations
//   @override
//   bool containsSingleton(String name) => _singletons.containsKey(name);
  
//   @override
//   Future<bool> isSingleton(String name) async => throw UnimplementedError();

//   @override
//   void addInitializationAwarePodProcessor(InitializationAwarePodProcessor processor) {
//     // implement addInitializationAwarePodProcessor
//   }

//   @override
//   void addStringValueResolver(StringValueResolver valueResolver) {
//     // implement addStringValueResolver
//   }

//   @override
//   void clearMetadataCache() {
//     // implement clearMetadataCache
//   }

//   @override
//   void clearSingletonCache() {
//     // implement clearSingletonCache
//   }

//   @override
//   bool containsDefinition(String name) {
//     // implement containsDefinition
//     throw UnimplementedError();
//   }

//   @override
//   Future<bool> containsLocalPod(String name) {
//     // implement containsLocalPod
//     throw UnimplementedError();
//   }

//   @override
//   Future<bool> containsPod(String name) {
//     // implement containsPod
//     throw UnimplementedError();
//   }

//   @override
//   void copyConfigurationFrom(ConfigurablePodFactory otherFactory) {
//     // implement copyConfigurationFrom
//   }

//   @override
//   void destroyPod(String podName, Object podInstance) {
//     // implement destroyPod
//   }

//   @override
//   void destroyScopedPod(String podName) {
//     // implement destroyScopedPod
//   }

//   @override
//   void destroySingletons() {
//     // implement destroySingletons
//   }

//   @override
//   Future<Set<A>> findAllAnnotationsOnPod<A>(String podName, Class<A> type, bool allowPodProviderInit) {
//     // implement findAllAnnotationsOnPod
//     throw UnimplementedError();
//   }

//   @override
//   Future<A?> findAnnotationOnPod<A>(String podName, Class<A> type, [bool allowEagerInit = false]) {
//     // implement findAnnotationOnPod
//     throw UnimplementedError();
//   }

//   @override
//   List<String> getAliases(String name) {
//     // implement getAliases
//     throw UnimplementedError();
//   }

//   @override
//   ApplicationStartup getApplicationStartup() {
//     // implement getApplicationStartup
//     throw UnimplementedError();
//   }

//   @override
//   ConversionService? getConversionService() {
//     // implement getConversionService
//     throw UnimplementedError();
//   }

//   @override
//   PodDefinition getDefinition(String name) {
//     // implement getDefinition
//     throw UnimplementedError();
//   }

//   @override
//   List<String> getDefinitionNames() {
//     // implement getDefinitionNames
//     throw UnimplementedError();
//   }

//   @override
//   int getInitializationAwarePodProcessorCount() {
//     // implement getInitializationAwarePodProcessorCount
//     throw UnimplementedError();
//   }

//   @override
//   List<InitializationAwarePodProcessor> getInitializationAwarePodProcessors() {
//     // implement getInitializationAwarePodProcessors
//     throw UnimplementedError();
//   }

//   @override
//   RootPodDefinition getMergedPodDefinition(String podName) {
//     // implement getMergedPodDefinition
//     throw UnimplementedError();
//   }

//   @override
//   int getNumberOfPodDefinitions() {
//     // implement getNumberOfPodDefinitions
//     throw UnimplementedError();
//   }

//   @override
//   Future<Object> getObject(String name, {Class? type, List<PropertyValue>? args}) {
//     // implement getObject
//     throw UnimplementedError();
//   }

//   @override
//   PodFactory? getParentFactory() {
//     // implement getParentFactory
//     throw UnimplementedError();
//   }

//   @override
//   PodExpressionResolver? getPodExpressionResolver() {
//     // implement getPodExpressionResolver
//     throw UnimplementedError();
//   }

//   @override
//   List<String> getPodNames(Class type, {bool includeNonSingletons = false, bool allowEagerInit = false}) {
//     // implement getPodNames
//     throw UnimplementedError();
//   }

//   @override
//   List<String> getPodNamesForAnnotation<A>(Class<A> type) {
//     // implement getPodNamesForAnnotation
//     throw UnimplementedError();
//   }

//   @override
//   Iterator<String> getPodNamesIterator() {
//     // implement getPodNamesIterator
//     throw UnimplementedError();
//   }

//   @override
//   Future<Map<String, T>> getPodsOf<T>(Class<T> type, {bool includeNonSingletons = false, bool allowEagerInit = false}) {
//     // implement getPodsOf
//     throw UnimplementedError();
//   }

//   @override
//   Future<Map<String, Object>> getPodsWithAnnotation<A>(Class<A> type) {
//     // implement getPodsWithAnnotation
//     throw UnimplementedError();
//   }

//   @override
//   ObjectProvider<T> getProvider<T>(String podName, Class type, {bool allowEagerInit = false}) {
//     // implement getProvider
//     throw UnimplementedError();
//   }

//   @override
//   PodScope? getRegisteredScope(String scopeName) {
//     // implement getRegisteredScope
//     throw UnimplementedError();
//   }

//   @override
//   List<String> getRegisteredScopeNames() {
//     // implement getRegisteredScopeNames
//     throw UnimplementedError();
//   }

//   @override
//   int getSingletonCount() {
//     // implement getSingletonCount
//     throw UnimplementedError();
//   }

//   @override
//   Future<Class?> getType(String name, [bool allowInit = false]) {
//     // implement getType
//     throw UnimplementedError();
//   }

//   @override
//   bool hasStringValueResolver() {
//     // implement hasStringValueResolver
//     throw UnimplementedError();
//   }

//   @override
//   bool isAutowireCandidate(String podName, DependencyDesign descriptor) {
//     // implement isAutowireCandidate
//     throw UnimplementedError();
//   }

//   @override
//   bool isCachePodMetadata() => throw UnimplementedError();

//   @override
//   bool isCurrentlyInCreation(String podName) => throw UnimplementedError();

//   @override
//   bool isNameInUse(String name) => throw UnimplementedError();

//   @override
//   Future<bool> isPodProvider(String name, [RootPodDefinition? rpd]) => throw UnimplementedError();

//   @override
//   Future<bool> isPrototype(String name) => throw UnimplementedError();

//   @override
//   Future<bool> isTypeMatch(String name, Class type) => throw UnimplementedError();

//   @override
//   void preInstantiateSingletons() => throw UnimplementedError();

//   @override
//   void registerAlias(String name, String alias) => throw UnimplementedError();

//   @override
//   void registerDefinition(String name, PodDefinition pod) => throw UnimplementedError();

//   @override
//   void registerIgnoredDependency(Class type) => throw UnimplementedError();

//   @override
//   void registerResolvableDependency(Class type, Object? autowiredValue) => throw UnimplementedError();

//   @override
//   void registerScope(String scopeName, PodScope scope) => throw UnimplementedError();

//   @override
//   void removeDefinition(String name) => throw UnimplementedError();

//   @override
//   String? resolveStringValue(String value) => throw UnimplementedError();

//   @override
//   void setAllowCircularReferences(bool value) => throw UnimplementedError();

//   @override
//   void setAllowDefinitionOverriding(bool value) => throw UnimplementedError();

//   @override
//   void setApplicationStartup(ApplicationStartup applicationStartup) => throw UnimplementedError();

//   @override
//   void setCachePodMetadata(bool cachePodMetadata) => throw UnimplementedError();

//   @override
//   void setConversionService(ConversionService conversionService) => throw UnimplementedError();

//   @override
//   void setParentFactory(PodFactory? parentFactory) => throw UnimplementedError();

//   @override
//   void setPodExpressionResolver(PodExpressionResolver? resolver) => throw UnimplementedError();
  
//   @override
//   Future<T> getPod<T>(String name, {Class? type, List<PropertyValue>? args}) => throw UnimplementedError();
  
//   @override
//   Future<Object?> getSingleton(String name, {bool allowEarlyReference = true, ObjectFactory<Object>? factory}) async {
//     return _singletons[name];
//   }
  
//   @override
//   List<String> getSingletonNames() => _singletons.keys.toList();
  
//   @override
//   Future<void> registerSingleton(String name, {ObjectHolder<Object>? object, ObjectFactory<Object>? factory}) => throw UnimplementedError();
// }