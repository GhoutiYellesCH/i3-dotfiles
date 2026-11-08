### 📁 Directory Structure                                                                   
                                                                                               
    ~/.config/i3/                                                                              
    ├── config                     # Main entrypoint configuration file                        
    ├── configs/                   # Modular configuration files                               
    │   ├── colors.conf            # Window borders, focus, and background colors              
    │   ├── keybinds.conf          # Application shortcuts, navigation, and window controls    
    │   ├── rules.conf             # Window rules, resize mode, and floating rules             
    │   ├── settings.conf          # Inner/outer gaps and font definitions                     
    │   ├── startup.conf           # Autostart applications and display configuration          
    │   └── workdpaces.conf        # Workspace bindings (1–10)                                 
    ├── scripts/                   # 21 shell scripts for desktop utilities                    
    │   ├── Wallpaper.sh           # Random wallpaper switcher                                 
    │   ├── WallpaperSelect.sh     # Rofi wallpaper selection menu                             
    │   ├── Colors.sh              # Color palette generation/application                      
    │   ├── volumecontrol.sh       # Volume mute / adjustment helper                           
    │   ├── brightness.sh          # Display brightness control                                
    │   ├── screenshot.sh          # Screen capture script                                     
    │   ├── powermenu.sh           # Power menu via Rofi                                       
    │   ├── polybar_theme.sh       # Polybar theme switching                                   
    │   └── ...                    # (emoji, cliphist, updater, etc.)                          
    ├── Wallpapers/                # Collection of 90+ wallpaper images (.jpg, .png, .gif)     
    └── .cache/                    # Cache directory (e.g. current.png for active wallpaper)   
  ──────                                                                                       
  ### ⚙ Configuration Breakdown                                                                
                                                                                               
   File                                         │ Description
  ──────────────────────────────────────────────┼──────────────────────────────────────────────
   config                                       │ Sets modifier keys ($mod = Mod4, $alt =
                                                │ Mod1), includes files from configs/, and
                                                │ runs default background daemons (dex, xss-
                   │ ($mod+c), Rofi menus, volume controls (F9–F11), and standard
                   │ tiling/focus/layout movements.
   colors.conf     │ Color definitions for focused, inactive, unfocused, and urgent window
                   │ frames.
   rules.conf      │ Defines the interactive resize mode, 3px border defaults, and auto-
                   │ floating rules (Thunar, Eog, Yad, ranger).
   settings.conf   │ Configures gaps inner 10, gaps outer 0, and font (JetBrainsMono Nerd Font
                   │ 12).
   startup.conf    │ Sets wallpaper (feh), launches Polybar, runs Colors.sh, polkit.sh, and
                   │ clipboard daemon (greenclip).
   workdpaces.conf │ Workspaces 1 through 10 switching ($mod+1..0) and container movement
                   │ ($mod+Shift+1..0).
  ──────
  ### ⚠ Potential Issues Detected
  
  1. included vs include Directive:
  In config:4-9, lines 4–9 use included ~/.config/i3/configs/... instead of the standard i3    
  directive include ~/.config/i3/configs/....
  2. **Broken Command in startup.conf:15-17**:
  Lines 15–17 contain an unintended multi-line split:
    exec xrandr --output HDMI-1 --mode 2732
    2560x1536
    1440 --rate 60
      
  3. Typo in filename/include:
  workdpaces.conf is named workdpaces.conf instead of workspaces.conf.