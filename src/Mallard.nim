import nigui
import strformat
import os
from unicode import toLower
import json
import strutils

app.init()

var window = newWindow("Mallard")

window.onResize = proc(event: ResizeEvent) = 
    window.height = 207.scaleToDpi
    window.width = 388.scaleToDpi
    
var mainContainer = newLayoutContainer(Layout_Vertical)
mainContainer.padding = 12
mainContainer.widthMode = WidthMode_Expand
mainContainer.xAlign = XAlign_Center
mainContainer.yAlign = YAlign_Center

window.add(mainContainer)

# Add container for aligning choices horizontally
var optionContainer = newLayoutContainer(Layout_Horizontal)
mainContainer.add(optionContainer)

# Add container for selecting extra mod
var extraModContainer = newLayoutContainer(Layout_Vertical)
optionContainer.add(extraModContainer)

var modLabel = newLabel("Mod ")
extraModContainer.add(modLabel)
var extraMod = newComboBox(@["None", "BetterDiscord", "SmartCord"])
extraModContainer.add(extraMod)

# Add container for selecting Discord channel
var discordChannelContainer = newLayoutContainer(Layout_Vertical)
optionContainer.add(discordChannelContainer)

var channelLabel = newLabel("Channel ")
discordChannelContainer.add(channelLabel)

# An unbelievable amount of shit gets done here

# Update server, I *guess* this counts as a config option if you change your GooseUpdate server
const updatesUrl = "https://updates.goosemod.com"

# Discord per-platform module folder parent
var baseDirectory: string
case hostOS:
    of "windows":
        baseDirectory = os.getEnv("appdata")
    of "macosx":
        baseDirectory = joinPath(os.getHomeDir(), "~/Library/Application Support")
    of "linux":
        baseDirectory = joinPath(os.getHomeDir(), ".config")
    else:
        window.alert(fmt"{hostOS} is not a supported platform.", "Unsupported platform")
        app.quit()

# A list of every single Discord channel
# Note that Stable is only here for labels in the UI, the string isn't used for generating anything
const discordChannels = ["Stable", "Canary", "PTB", "Development"]

# Function for formatting Discord paths
proc getChannelPath(channel: string): string =
    # Path to passed Discord channel's modules directory
    var channelPath = os.joinPath(baseDirectory, "discord")

    # Discord stable doesn't have a suffix so it's ignored
    if channel != "Stable":
        channelPath = channelPath & channel.toLower()
    
    return channelPath

# Function for getting all installed Discord channels
proc getAllInstalledInstances(): seq[string] =
    var installedChannels: seq[string]
    for channel in discordChannels:
        if fileExists(os.joinPath(getChannelPath(channel), "settings.json")):
            installedChannels.add(channel)
    
    return installedChannels

# Add installed Discord channels to the channel combo box
var discordChannel = newComboBox(getAllInstalledInstances())
discordChannelContainer.add(discordChannel)

# This checkbox is for whether you want GooseMod or not
var installGm = newCheckbox("GooseMod")
installGm.checked = true
mainContainer.add(installGm)

# This button handles installation of GooseUpdate in clients that have not yet been injected into
var installButton = newButton("Install")
# Disable the button so that handleButtons can handle it
installButton.enabled = false
installButton.widthMode = WidthMode_Fill

# This button handles uninstallation of GooseUpdate in clients that have been injected into
var uninstallButton = newButton("Uninstall")
uninstallButton.enabled = false
# Disable the button so that handleButtons can handle it
uninstallButton.enabled = false
uninstallButton.widthMode = WidthMode_Fill

# handleButtons will update these variables and turn them into their names
# Note to self, adderall makes you program, it doesn't make you program good
var selectedInstancePath: string
var selectedInstanceSettingsPath: string

proc handleButtons() =
    # Handle for if no Discord instances are found
    if discordChannel.value != "":
        selectedInstancePath = getChannelPath(discordChannel.value)
        selectedInstanceSettingsPath = os.joinPath(selectedInstancePath, "settings.json")
        
        # Parse Discord instance's settings.json
        let parsedSettings = parseFile(selectedInstanceSettingsPath)

        # This checks to see if a replacement update server is set 
        if parsedSettings.hasKey("NEW_UPDATE_ENDPOINT") or parsedSettings.hasKey("NEW_UPDATE_ENDPOINT"):
            uninstallButton.enabled = true
            installButton.enabled = false
            extraMod.enabled = false
            installGm.enabled = false
        else:
            uninstallButton.enabled = false
            installButton.enabled = true
            extraMod.enabled = true
            installGm.enabled = true

# Add the installation buttons
mainContainer.add(installButton)
mainContainer.add(uninstallButton)

# This gets called to make sure everything is initialized
handleButtons()

discordChannel.onChange = proc(event: ComboBoxChangeEvent) =
    # I keep calling this function to replace all of the variables and update the UI components in certain situations
    handleButtons()


installButton.onClick = proc(event: ClickEvent) =
    # I would've made the install button be disabled instead of giving the user an error when neither are set, but the event for checkbox updates is inconsistent and buggy
    if installGm.checked != false or extraMod.value != "None":
        # Create a list of mods to install
        var modList: seq[string]

        if extraMod.value != "None":
            modList.add(extraMod.value.toLower())

        if installGm.checked:
            modList.add("goosemod")
        
        # Join the mod list with "+" as a separator since that's what GooseUpdate uses
        let modString = modList.join("+")
        var parsedSettings = parseFile(selectedInstanceSettingsPath)

        # Nim really sucks with Json. Setting a value requires you use % to make it compatible with jJson
        parsedSettings.add("NEW_UPDATE_ENDPOINT", %fmt"{updatesUrl}/{modString}/")
        parsedSettings.add("UPDATE_ENDPOINT", %fmt"{updatesUrl}/{modString}")

        # Write prettified modified settings.json
        writeFile(selectedInstanceSettingsPath, parsedSettings.pretty())
        window.alert(fmt"Successfully installed to Discord {discordChannel.value}! Restart Discord {discordChannel.value} to use your mod(s).", "Success!")
    else:
        window.alert("You must select at least one client mod to install.", "Mallard can't install nothing!")
    handleButtons()

uninstallButton.onClick = proc(event: ClickEvent) =
    var parsedSettings = parseFile(selectedInstanceSettingsPath)

    # Setting the update endpoint back shouldn't normally uninstall mods, but maybe GooseUpdate has something built-in handling uninstallation?
    parsedSettings.delete("NEW_UPDATE_ENDPOINT")
    parsedSettings.delete("UPDATE_ENDPOINT")

    writeFile(selectedInstanceSettingsPath, parsedSettings.pretty())

    # To follow up on this, in my testing whenever I removed the modified update endpoints my client would error out the next time I started it, and then after another restart it'd return to normal
    window.alert(fmt"Successfully uninstalled from Discord {discordChannel.value}! Your client may have an error when it starts up, just click OK and try again.", "Success!")

    # This is genuinely the nastiest code I've ever wrote
    handleButtons()

window.show()

app.run()