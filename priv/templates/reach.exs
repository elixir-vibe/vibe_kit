[
  # Reach architecture policy is project-specific. Define layers when the
  # module boundaries are stable enough to enforce, then remove the leading
  # comment markers from the example below.
  #
  # layers: [
  #   foundation: ["MyApp.Core.*", "MyApp.Domain.*"],
  #   services: ["MyApp.Services.*", "MyApp.Infrastructure.*"],
  #   presentation: ["MyAppWeb.*", "MyApp.CLI.*"]
  # ],
  # deps: [
  #   forbidden: [
  #     {:foundation, :services},
  #     {:foundation, :presentation},
  #     {:services, :presentation}
  #   ]
  # ]
]
