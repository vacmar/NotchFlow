# Contributing

## Development setup

- macOS 14+
- Xcode 15.3+ (or newer command line tools)
- Swift 5.10+

## Run

```bash
swift build
swift run
```

## Branching

- `main` is stable integration branch.
- Use short-lived feature branches and open PRs.

## Pull request checklist

- Keep PR scope focused.
- Build passes locally.
- Update docs when behavior changes.
- Include screenshots or short recordings for UI changes.

## Media provider architecture

Providers should implement a common protocol and avoid blocking UI thread work.
