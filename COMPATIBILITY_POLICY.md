# Compatibility Policy

As an open-source project, all activities happened when the maintainers have spare time and energy.
The support range is limited due to the above condition.
Therefore, we have a general compatibility policy to help people
that are not actively adapting SDK updates or intended to use any old SDKs to acknowledge the support range.

## Policy Details

For all packages, the oldest Dart SDK we typically support
is one that was **released less than 2 years ago**.

### Exceptions

- The minimum SDK version will follow the dependencies' requirement.
  For example: `http2: ^2.1.0` requires Dart SDK >=3.0.0.
- The implementation can no longer compatible between the latest and previous SDKs.
- Previous SDKs have security issues that require to use a new version.

To raise your suggestions and reports, use the issue tracker
or contact cfug-team@googlegroups.com if you want to do this privately.
