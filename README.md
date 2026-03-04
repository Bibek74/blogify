# Blogify 
## Sprint-3 video
https://youtu.be/zUvEoIKCVYI

## API host configuration

By default, the app connects to:
- Android emulator: `http://10.0.2.2:5000`
- iOS simulator / desktop / web: `http://localhost:5000`

To run on a physical phone, pass your backend machine LAN IP:

```bash
flutter run --dart-define=API_HOST=192.168.254.53 --dart-define=API_PORT=5000
```
