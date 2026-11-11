# rn-set-color-scheme-no-change

![Build](https://github.com/YevheniiKotyrlo/rn-set-color-scheme-no-change/workflows/Pre%20Merge%20Checks/badge.svg)

`Appearance.setColorScheme` emits no `change`, so a component that reads `useColorScheme()` keeps the old scheme until the platform reports it, while a component that re-renders for another reason reads the new one from `Appearance.getColorScheme()`.

`ReproducerApp/App.tsx` renders `useColorScheme()` in one component and `Appearance.getColorScheme()` in a sibling that holds a counter. One press calls `Appearance.setColorScheme(next)` and bumps the counter. After each commit, each reader logs what the screen shows, and a `change` listener logs when it runs.

## Run it

With an Android device or emulator on adb:

```bash
bash repro.sh
```

It builds the release APK, installs and opens it, taps the button, and prints the app's log. It exits 1 while a commit after the press shows the two readers disagreeing, 0 once none does, and 2 when a step fails first.

By hand: `yarn install` in `ReproducerApp`, then `yarn android`, press the grey area once, and read the `[repro]` lines in Metro's log.
