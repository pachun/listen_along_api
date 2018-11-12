# Listen Along

Listen along to music with your friends through Spotify.

# Test

To test without generating a coverage report:

```bash
bundle exec rspec
```

To test and generate a coverage report (a bit slower):

```bash
DISABLE_SPRING=true COVERAGE=true bundle exec rspec
```

The coverage report may be opened with:

```bash
open coverage/index.html
```

# Run

```bash
bundle exec rails s
```

