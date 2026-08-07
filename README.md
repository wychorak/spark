# Spark — legacy Flutter prototype

> Status: archived and superseded by [spark-new](https://github.com/wychorak/spark-new).

This repository contains the first Flutter implementation of Spark, a social discovery and dating-app concept. It is retained to document the product's earlier architecture and UI exploration.

## Implemented areas

- authentication and age-gating screens
- profile onboarding and editing
- discovery, matching and chat interfaces
- safety and photo-verification flows
- Supabase-oriented service architecture
- premium/paywall UI

## Stack

Flutter, Dart, Riverpod, GoRouter, Supabase and RevenueCat.

## Current condition

The project is not release-ready. The latest audit reports analyzer warnings and a stale widget test that references a removed `MyApp` class. Dependency constraints also lag behind current package releases. Active development moved to the React Native/Expo implementation in `spark-new`.
