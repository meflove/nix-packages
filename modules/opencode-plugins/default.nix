{self, ...}: {
  flake = _: {
    homeModules.${baseNameOf ./.} = {
      config,
      lib,
      pkgs,
      ...
    }: let
      jsonFormat = pkgs.formats.json {};
      cfg = config.programs.opencode.nixPlugins;
      plugins = self.legacyPackages.${pkgs.stdenv.hostPlatform.system}.opencodePlugins;
    in {
      options.programs.opencode.nixPlugins = {
        oh-my-opencode-slim = {
          enable = lib.mkEnableOption "enable plugin oh-my-opencode-slim";
          settings = lib.mkOption {
            inherit (jsonFormat) type;
            default = {
              preset = "openai";
              presets = {
                openai = {
                  orchestrator = {
                    model = "openai/gpt-5.6-terra";
                    variant = "high";
                    skills = [
                      "*"
                    ];
                    mcps = [
                      "*"
                      "!context7"
                    ];
                  };
                  oracle = {
                    model = "openai/gpt-5.6-sol";
                    variant = "high";
                    skills = [
                      "simplify"
                    ];
                    mcps = [];
                  };
                  librarian = {
                    model = "openai/gpt-5.6-luna";
                    variant = "low";
                    skills = [];
                    mcps = [
                      "context7"
                      "gh_grep"
                    ];
                  };
                  explorer = {
                    model = "openai/gpt-5.6-luna";
                    variant = "low";
                    skills = [];
                    mcps = [];
                  };
                  designer = {
                    model = "openai/gpt-5.6-luna";
                    variant = "medium";
                    skills = [];
                    mcps = [];
                  };
                  fixer = {
                    model = "openai/gpt-5.6-luna";
                    variant = "high";
                    skills = [];
                    mcps = [];
                  };
                };
                opencode-go = {
                  orchestrator = {
                    model = "opencode-go/minimax-m3";
                    variant = "thinking";
                  };
                  oracle = {
                    model = "opencode-go/qwen3.7-max";
                    variant = "max";
                  };
                  librarian = {
                    model = "opencode-go/deepseek-v4-flash";
                    variant = "high";
                  };
                  explorer = {
                    model = "opencode-go/deepseek-v4-flash";
                    variant = "high";
                  };
                  designer = {
                    model = "opencode-go/kimi-k2.7-code";
                  };
                  fixer = {
                    model = "opencode-go/deepseek-v4-flash";
                    variant = "high";
                  };
                  observer = {
                    model = "opencode-go/mimo-v2.5";
                  };
                };
              };
            };
            example = {
              preset = "zai";
              presets.zai = {
                orchestrator = {
                  model = "zai-coding-plan/glm-5.3";
                  variant = "max";
                  skills = ["*"];
                  mcps = [
                    "*"
                    "!context7"
                  ];
                };
                oracle = {
                  model = "zai-coding-plan/glm-5.3";
                  variant = "max";
                  mcps = [];
                };
                librarian = {
                  model = "zai-coding-plan/glm-5.3-flash";
                  skills = [];
                  mcps = [
                    "context7"
                    "github"
                    "nixos"
                  ];
                };
                explorer = {
                  model = "zai-coding-plan/glm-5.3-flash";
                  skills = [];
                  mcps = [];
                };
                designer = {
                  model = "zai-coding-plan/glm-5.3-flash";
                  variant = "high";
                  skills = [];
                  mcps = [];
                };
                fixer = {
                  model = "zai-coding-plan/glm-5.3-flash";
                  variant = "max";
                  skills = [];
                  mcps = [];
                };
              };
            };
            description = ''
              Configuration written to {file}`$XDG_CONFIG_HOME/opencode/oh-my-opencode-slim.json`.
              See <https://github.com/alvinunreal/oh-my-opencode-slim#preset-docs> for the documentation.

              Note, `"$schema" = "https://unpkg.com/oh-my-opencode-slim@latest/oh-my-opencode-slim.schema.json"` is automatically added to the configuration.
            '';
          };
        };

        opencode-dynamic-context-pruning = {
          enable = lib.mkEnableOption ''
            enable plugin opencode-dynamic-context-pruning

            WARNING: OpenCode V2 plugin API incompatibility — DOES NOT WORK YET.
            The plugin ships the OpenCode V1 plugin API (bare async factory
            default export) which OpenCode V2 rejects with a SchemaError
            ("Expected object, got async fn"). Upstream has no V2 port as of
            2026-09-02. Enabling it on OpenCode V2 only produces load-failure
            warnings in the server log; nothing breaks, but nothing works
            either. Works on OpenCode V1 only.
          '';
          settings = lib.mkOption {
            inherit (jsonFormat) type;
            default = {
              enabled = true;
              autoUpdate = false;
              debug = false;
              pruneNotification = "detailed";
              pruneNotificationType = "chat";
              commands = {
                enabled = true;
                protectedTools = [
                ];
              };
              manualMode = {
                enabled = false;
                automaticStrategies = true;
              };
              turnProtection = {
                enabled = false;
                turns = 4;
              };
              experimental = {
                allowSubAgents = false;
                customPrompts = false;
              };
              protectedFilePatterns = [
              ];
              compress = {
                mode = "range";
                permission = "allow";
                showCompression = false;
                summaryBuffer = true;
                maxContextLimit = 100000;
                minContextLimit = 50000;
                nudgeFrequency = 5;
                iterationNudgeThreshold = 15;
                nudgeForce = "soft";
                protectedTools = [
                ];
                protectTags = false;
                protectUserMessages = false;
              };
              strategies = {
                deduplication = {
                  enabled = true;
                  protectedTools = [
                  ];
                };
                purgeErrors = {
                  enabled = true;
                  turns = 4;
                  protectedTools = [
                  ];
                };
              };
            };
            example = {
              pruneNotification = "detailed";
              compress = {
                mode = "range";
                maxContextLimit = 100000;
                minContextLimit = 50000;
              };
              turnProtection = {
                enabled = true;
                turns = 4;
              };
            };
            description = ''
              Configuration written to {file}`$XDG_CONFIG_HOME/opencode/dcp.json`.
              See <https://github.com/Opencode-DCP/opencode-dynamic-context-pruning#configuration> for the documentation.

              Note, `"$schema" = "https://raw.githubusercontent.com/Opencode-DCP/opencode-dynamic-context-pruning/master/dcp.schema.json"` is automatically added to the configuration.
            '';
          };
        };

        opencode-notify = {
          enable = lib.mkEnableOption ''
            enable plugin opencode-notify

            WARNING: OpenCode V2 plugin API incompatibility — DOES NOT WORK YET.
            The packaged npm dist (0.3.1) ships the OpenCode V1 plugin API
            which OpenCode V2 rejects with a SchemaError. Upstream has no V2
            port as of 2026-09-02. Works on OpenCode V1 only.
          '';
          settings = lib.mkOption {
            inherit (jsonFormat) type;
            default =
              {
                notifyChildSessions = false;
                terminal = "ghostty";
                sounds = {
                  idle = "Glass";
                  error = "Basso";
                  permission = "Submarine";
                  question = "Submarine";
                };
                quietHours = {
                  enabled = false;
                  start = "22:00";
                  end = "08:00";
                };
              }
              // {
                # npm dist 0.3.1 additionally reads these (undocumented upstream)
                focusAfterAction = true;
                notifyOnIdle = true;
              };
            example = {
              notifyChildSessions = false;
              terminal = "ghostty";
              sounds = {
                idle = "Glass";
                error = "Basso";
                permission = "Submarine";
                question = "Submarine";
              };
              quietHours = {
                enabled = false;
                start = "22:00";
                end = "08:00";
              };
            };
            description = ''
              Configuration written to {file}`$XDG_CONFIG_HOME/opencode/opencode-notify.json`.
              See <https://github.com/kdcokenny/opencode-notify#configuration> for the documentation.

              Note: the packaged npm dist (0.3.1) reads `opencode-notify.json` — the
              git-source builds read `kdco-notify.json`, but their sources are broken
              upstream (missing modules), so the published dist is what we ship.
              Keys consumed by 0.3.1: `notifyChildSessions`, `terminal`,
              `sounds.permission`, `sounds.error`, `quietHours.*`,
              `focusAfterAction`, `notifyOnIdle`, `nativeMacNotifications`.
              `timeout`, `sounds.idle` and `sounds.question` are accepted but ignored
              (idle/question fall back to `sounds.permission`).

              On Linux, desktop notifications require `notify-send` (libnotify) on PATH.
            '';
          };
        };

        opencode-mem = {
          enable = lib.mkEnableOption ''
            enable plugin opencode-mem

            WARNING: OpenCode V2 plugin API incompatibility — DOES NOT WORK YET.
            dist/plugin.js exports `{ id, server }` without the `setup` key
            OpenCode V2 requires (SchemaError "Missing key effect/setup").
            Upstream has no V2 port as of 2026-09-02. Works on OpenCode V1
            only. The ollama embedding settings in the host config stay
            dormant until a V2 port lands.
          '';
          settings = lib.mkOption {
            inherit (jsonFormat) type;
            default = {
              # Storage location for vector database
              storagePath = "~/.opencode-mem/data";

              userEmailOverride = "";
              userNameOverride = "";

              # Enable web UI for managing memories (accessible at http://localhost:4747)
              webServerEnabled = true;
              # Port for web UI server
              webServerPort = 4747;
              # Host address for web UI (use 127.0.0.1 for local only, 0.0.0.0 for network access)
              webServerHost = "127.0.0.1";

              # Maximum vectors per database shard (auto-creates new shard when limit reached)
              maxVectorsPerShard = 50000;
              # Automatically delete old memories based on retention period
              autoCleanupEnabled = true;
              # Days to keep memories before auto-cleanup (only if autoCleanupEnabled is true)
              autoCleanupRetentionDays = 30;
              # Automatically detect and remove duplicate memories
              deduplicationEnabled = true;
              # Similarity threshold (0-1) for detecting duplicates (higher = stricter)
              deduplicationSimilarityThreshold = 0.90;

              # Default scope for memory list/search queries
              # "project" keeps queries within the current project, "all-projects" searches across all project shards
              memory = {
                defaultScope = "project";
              };

              # Days to keep AI session history before cleanup
              aiSessionRetentionDays = 7;

              # Temperature for AI API requests (set to false to omit parameter for models that don't support it)
              # Some reasoning models (like o1, o3, gpt-5) don't support temperature parameter
              # Set to false and add "memoryTemperature": false in config when using such models
              memoryTemperature = 0.3;

              # Extra parameters to include in API request body
              # Useful for local inference servers (e.g. llama-server with --jinja) that support
              # additional parameters like disabling thinking/reasoning mode
              # Example for Qwen3 models: { "enable_thinking": false }
              # memoryExtraParams = {};

              # Language for auto-capture summaries (default: "auto" for auto-detection)
              # Options: "auto", "en", "id", "zh", "ja", "es", "fr", "de", "ru", "pt", "ar", "ko"
              # autoCaptureLanguage = "auto";

              # Show toast when memory is auto-captured
              showAutoCaptureToasts = true;
              # Show toast when user profile is updated
              showUserProfileToasts = true;
              # Show toast for error messages
              showErrorToasts = true;

              # ============================================
              # User Profile System
              # ============================================

              # Analyze user prompts every N prompts to build/update your user profile
              # When N uncaptured prompts accumulate, AI will analyze them to identify:
              # - User preferences (code style, communication style, tool preferences)
              # - User patterns (recurring topics, problem domains, technical interests)
              # - User workflows (development habits, sequences, learning style)
              # - Skill level (overall and per-domain assessment)
              userProfileAnalysisInterval = 10;

              # Days before inactive items (all types) are eligible for removal
              userProfileStaleDays = 2;

              # Number of preferences shown in UI
              userProfileDisplayPreferences = 20;

              # Number of patterns shown in UI
              userProfileDisplayPatterns = 15;

              # Number of workflows shown in UI
              userProfileDisplayWorkflows = 10;

              # Number of preferences injected into LLM conversation context
              # Keep this small — the strongest signals are enough; more dilute LLM attention
              userProfileInjectPreferences = 5;

              # Number of patterns injected into LLM conversation context
              userProfileInjectPatterns = 5;

              # Number of workflows injected into LLM conversation context
              userProfileInjectWorkflows = 3;

              # Days before preference confidence starts to decay (if not reinforced)
              # Preferences that aren't seen again will gradually lose confidence and be removed
              userProfileConfidenceDecayDays = 30;

              # Number of profile versions to keep in changelog (for rollback/debugging)
              # Older versions are automatically cleaned up
              userProfileChangelogRetentionCount = 5;

              # Minimum evidence count for a preference/pattern to survive confidence decay
              # Items confirmed fewer times are more likely to be pruned when confidence decays
              userProfileMinEvidenceForRetention = 3;

              # Periodically merge duplicate or irrelevant profile items with the configured AI provider
              userProfileAutoCleanupEnabled = true;
              # Number of analyzed user prompts between automatic AI cleanup runs
              userProfileAutoCleanupInterval = 100;

              # Enable LLM validation of existing preferences against recent behavior.
              # When enabled, each analysis round checks if top-5 preferences still match recent prompts.
              # Experimental — disabled by default.
              userProfileValidationEnabled = false;

              # ============================================
              # Search Settings
              # ============================================

              # Minimum similarity score (0-1) for memory search results
              similarityThreshold = 0.6;

              # Maximum number of memories to return in search results
              maxMemories = 10;

              # ============================================
              # Advanced Settings
              # ============================================

              # Inject user profile into AI context (preferences, patterns, workflows)
              injectProfile = true;
            };
            example = {
              storagePath = "~/.opencode-mem/data";
              embeddingModel = "Xenova/nomic-embed-text-v1";
              memory.defaultScope = "project";
              webServerEnabled = true;
              webServerPort = 4747;
              autoCaptureEnabled = true;
              opencodeProvider = "anthropic";
              opencodeModel = "inherit";
            };
            description = ''
              Configuration written to {file}`$XDG_CONFIG_HOME/opencode/opencode-mem.jsonc` (as plain JSON, which is valid JSONC).
              See <https://github.com/tickernelz/opencode-mem#configuration-essentials> for the documentation.

              The plugin reads `opencode-mem.jsonc` first, so this module writes that exact
              path; otherwise the plugin would shadow it with its auto-generated template.
            '';
          };
        };
      };

      config = lib.mkMerge [
        (lib.mkIf cfg.oh-my-opencode-slim.enable {
          xdg.configFile = {
            "opencode/plugins/oh-my-opencode-slim".source = plugins.oh-my-opencode-slim;
            "opencode/oh-my-opencode-slim.json".text = builtins.toJSON ({
                "$schema" = "https://unpkg.com/oh-my-opencode-slim@latest/oh-my-opencode-slim.schema.json";
              }
              // cfg.oh-my-opencode-slim.settings);
          };
          programs.opencode.settings.plugins = ["oh-my-opencode-slim"];
        })
        (lib.mkIf cfg.opencode-dynamic-context-pruning.enable {
          xdg.configFile = {
            "opencode/plugins/opencode-dynamic-context-pruning".source = plugins.opencode-dynamic-context-pruning;
            "opencode/dcp.json".text = builtins.toJSON ({
                "$schema" = "https://raw.githubusercontent.com/Opencode-DCP/opencode-dynamic-context-pruning/master/dcp.schema.json";
              }
              // cfg.opencode-dynamic-context-pruning.settings);
          };
          programs.opencode.settings.plugins = ["opencode-dynamic-context-pruning"];
        })
        (lib.mkIf cfg.opencode-notify.enable {
          xdg.configFile = {
            "opencode/plugins/opencode-notify".source = plugins.opencode-notify;
            "opencode/opencode-notify.json".text = builtins.toJSON cfg.opencode-notify.settings;
          };
          programs.opencode.settings.plugins = ["opencode-notify"];
        })
        (lib.mkIf cfg.opencode-mem.enable {
          xdg.configFile = {
            "opencode/plugins/opencode-mem".source = plugins.opencode-mem;
            "opencode/opencode-mem.jsonc".text = builtins.toJSON cfg.opencode-mem.settings;
          };
          programs.opencode.settings.plugins = ["opencode-mem"];
        })
      ];
    };
  };
}
