# Ugo

Ugo v2.0+ Flutter App for iOS and Android.

## Flutter Details
- [Flutter](https://flutter.io)
- [IDE Setup](https://flutter.io/using-ide/)
- Currently using the Flutter Beta, v0.2.3 for building

## Flutter Project Structure
- External dependencies
  - Loaded via the pubspec.yaml file at the top level of the project.

- Android and iOS Project settings
  - Found in the android and ios directories, respectively
  - These files are used when building the app for each platform

- lib directory
  - Location of the dart files for the Flutter project.
  - main.dart is the starting place

- Assets directory
  - Home for the fonts and images (at various scales) used in the project

- Details for lib directory
  - Models
    - Home of the models for the various objects that the OpenCart API provides in its responses. Primarily used for mapping JSON from the API to Dart objects for simpler use throughout the rest of the app.
  - Pages
    - The screens for the app. Where useful, the pages are divided into Stateless/Stateful widgets. This results in a pattern similar to the Component/Container pattern often seen in React projects, in which stateful containers handle the logic to construct a stateless presentation component. Where a one-off widget was all that was needed, the business and presentation logic is often combined into a single page widget.
    - Checkout Page is where all of the checkout logic is held, to be triggered in sequence during the OpenCart/Stripe checkout process.
    - Most of the work for the app is in the pages.
  - Utilities
    - Various utility classes used throughout the app. Includes the constants file that holds much of the hardcoded data for the app, as well as the ApiManager class which is used to handle network requests and responses to/from the API.
    - Secrets file holds sensitive constants/parameters that are used and shouldn’t be checked into repo.
  - Widgets
    - Additional widgets used in various pages in the app.