# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.3]
### Changed
- Removed `privileged: true` - now using specific capabilities only
- Made `CAP_SYS_ADMIN` optional (commented out by default) due to high privileges
- Made `CAP_SYS_RESOURCE` optional (commented out by default) - only needed for kernels < 5.11
- Added `CAP_NET_RAW` to default capabilities for network monitoring support
- Added comprehensive documentation about capability requirements and when high-privilege caps are needed

## [1.0.2]
### Changed
- Fixed pod naming to include release name

## [1.0.1]
### Changed
- Fixed pod naming to remove duplicate "obi" suffix
- Made OTLP endpoint namespaces dynamic using release namespace


## [1.0.0]
### Added
- Initial release of OBI subchart
- Zero-code auto-instrumentation for Kubernetes using eBPF
- Support for traces and metrics export via OTLP
- Kubernetes service discovery with configurable filters


