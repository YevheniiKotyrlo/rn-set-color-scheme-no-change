import { useEffect, useLayoutEffect, useState } from 'react';
import {
  Appearance,
  Pressable,
  StyleSheet,
  Text,
  useColorScheme,
  View,
} from 'react-native';

// The scheme each reader shows on screen, as of its last commit.
const shown = { hook: '', direct: '' };
let pressedAt = 0;

const log = (line: string) => console.log(`[repro] ${line}`);

function reportCommit(reader: string) {
  if (shown.hook === '' || shown.direct === '') {
    return;
  }
  const agreement = shown.hook === shown.direct ? 'agree' : 'DISAGREE';
  log(
    `${reader} committed: the screen shows useColorScheme() ${shown.hook} and Appearance.getColorScheme() ${shown.direct} (${agreement})`,
  );
}

function HookReader() {
  const scheme = useColorScheme() ?? 'null';
  useLayoutEffect(() => {
    shown.hook = scheme;
    reportCommit('the useColorScheme() reader');
  });
  return <Text style={styles.line}>useColorScheme(): {scheme}</Text>;
}

function DirectReader() {
  const [presses, setPresses] = useState(0);
  const scheme = Appearance.getColorScheme() ?? 'null';
  useLayoutEffect(() => {
    shown.direct = scheme;
    reportCommit('the Appearance.getColorScheme() reader');
  });
  const press = () => {
    const next = scheme === 'dark' ? 'light' : 'dark';
    log(
      `press ${presses + 1}: Appearance.setColorScheme('${next}') and a state update`,
    );
    pressedAt = Date.now();
    Appearance.setColorScheme(next);
    setPresses(presses + 1);
  };
  return (
    <Pressable style={styles.button} onPress={press} testID="toggle">
      <Text style={styles.line}>Appearance.getColorScheme(): {scheme}</Text>
      <Text style={styles.line}>presses: {presses}</Text>
    </Pressable>
  );
}

function App() {
  useEffect(() => {
    const subscription = Appearance.addChangeListener(({ colorScheme }) => {
      log(
        `change listener: ${colorScheme ?? 'null'}, ${Date.now() - pressedAt} ms after the press`,
      );
    });
    log('ready');
    return () => subscription.remove();
  }, []);
  return (
    <View style={styles.screen}>
      <HookReader />
      <DirectReader />
    </View>
  );
}

const styles = StyleSheet.create({
  screen: { flex: 1, paddingTop: 80, backgroundColor: '#888888' },
  button: { flex: 1, padding: 24, backgroundColor: '#cccccc' },
  line: { fontSize: 20, color: '#000000', padding: 8 },
});

export default App;
