# OTP Actors & Supervisors

*This page will be filled in when we build the `gleam-expiry` worker.*

## What's an OTP actor?

An actor is a lightweight process on the BEAM VM that:

- Has its own mailbox (message queue)
- Processes one message at a time
- Can crash and be restarted by a supervisor

## Gleam's actor model

```gleam
// An actor that responds to messages
pub fn start() {
  actor.start(initial_state, fn(message, state) {
    case message {
      Tick -> {
        // do work
        actor.continue(state)
      }
    }
  })
}
```

## Supervision

OTP supervisors watch child processes and restart them on crash. This is the "let it crash" philosophy — instead of handling every error, let the process die and come back clean.

*More details coming with the gleam-expiry implementation.*
