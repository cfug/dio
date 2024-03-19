# Contributing Guidelines

Language: English | [简体中文](CONTRIBUTING-ZH.md)

First of all, thank you for considering contributing to the `dio` project! Open source projects like this one grow and thrive thanks to the contributions from people like you. Whether you're fixing bugs, adding new features, improving the documentation, or even reporting issues, every contribution is valuable and appreciated.

This document provides some guidelines to help ensure that your contributions are as effective as possible. Please take a moment to read through these guidelines before submitting your contribution.

Remember, everyone contributing to this project is expected to follow our code of conduct. This helps ensure a positive and inclusive environment for all contributors.

Thank you again for your contributions, and we look forward to seeing what you will bring to the `dio` project!

## Creating Good Tickets

> [!TIP]
> Before creating a new issue, it's a good practice to search for open tickets and pull requests to avoid duplicates.

### Bug Reports

When reporting a bug, please include the following information:

1. **Title**: A brief, descriptive title for the bug.
2. **Package**: Specify which package has the problem.
3. **Version**: The version of the package you are using.
4. **Operating System**: The OS on which the problem occurs.
5. **Adapter**: Specify which adapter(s) are used.
6. **Output of `flutter doctor -v`**: Required when used with Flutter.
7. **Dart Version**: The version of Dart you are using.
8. **Steps to Reproduce**: Detailed steps on how to reproduce the bug.
9. **Expected Result**: What you expected to happen.
10. **Actual Result**: What actually happened. Include logs, screenshots, or any other relevant information.

### Feature Requests

When requesting a new feature, please include the following information:

1. **Title**: A brief, descriptive title for the feature request.
2. **Request Statement**: Describe the problem that you believe the `dio` project could solve but currently doesn't.
3. **Solution Brainstorm**: Share your ideas on how the problem could be solved. If you don't have a specific solution in mind, that's okay too!

> [!TIP]
> Remember, the more information you provide, the easier it is for us to understand and address the issue. Thank you for your contributions!
> Please refrain from commenting on old, closed tickets. If an old issue seems related but doesn't fully address your problem, it's best to open a new ticket and reference the old one instead.

## Development

This project uses [Melos](https://github.com/invertase/melos) to manage the mono-repo and most tasks. Melos is a tool that optimizes the workflow for multi-package Dart and Flutter projects. For more information on how to use Melos, please refer to the [Melos documentation](https://melos.invertase.dev).


### Setup

To get started, you'll need to install Melos globally:

```bash
dart pub global activate melos
```

After installing Melos, you can clone the repository and install the dependencies:

```bash
git clone https://github.com/cfug/dio.git
cd dio
melos bootstrap
```

## Submitting changes

Before submitting your changes as a pull request, please make sure to format and analyze your and run the all tests. Here are the main melos scripts you should be aware of:

### Code quality

To format (and fix) all packages, run: 
```bash
melos run format
# OR
melos run format:fix
```

To analyze all packages, run: 
```bash
melos run analyze
```

### Testing

To run all tests, use: 
```bash
melos run test
```

Individual test targets can be run with the appropriate scripts:
```bash
melos run test:vm
melos run test:web
melos run test:web:chrome
melos run test:web:firefox
```
