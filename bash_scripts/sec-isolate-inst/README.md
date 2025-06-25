This is a bash script to quickly isolate an instance that is suspected to have been "compromised" from a security point of view. This would be a step as part of Incidence Response.

_Note_: Modifying security-groups does not immediately break the existing connections. They only affect new connections. For a more immediate interruption to traffic, NACL would be a better option, which we will try to tackle in a different place.

The idea is to either
1. Remove all ingress and egress existing security-groups on the instance, which would isolate the instance and even block us from connecting to the instance for investigation.
2. Remove all ingress and egress existing security-groups and add a restrictive security-group that only allows connections from specific secure networks for investigation.

## 1. Remove all ingress and egress security-groups

```sh

```