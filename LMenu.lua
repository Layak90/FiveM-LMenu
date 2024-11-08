-- layakui_core.lua

local LayakUI = {
    _VERSION = '1.0.0',
    _AUTHOR = 'Layak',
    Menus = {},
    CurrentMenu = nil,
    Pool = {},
    Settings = {
        MaxOptions = 10,
        SelectableColors = {r = 255, g = 255, b = 255, a = 255},
        UnSelectableColors = {r = 155, g = 155, b = 155, a = 255},
        BackgroundColor = {r = 0, g = 0, b = 0, a = 200},
        SubTitleBackgroundColor = {r = 0, g = 0, b = 0, a = 255},
    }
}

-- Protection contre la copie (à améliorer avec une vraie méthode d'obfuscation)
local function VerifyIntegrity()
    if GetCurrentResourceName() ~= 'layakui' then
        error('LayakUI: Unauthorized use detected.')
        return false
    end
    return true
end

if not VerifyIntegrity() then return end

-- Créer un nouveau menu
function LayakUI.CreateMenu(id, title, subtitle, x, y, width, maxOptions)
    if LayakUI.Menus[id] then return LayakUI.Menus[id] end
    
    local menu = {
        id = id,
        title = title or '',
        subtitle = subtitle or '',
        x = x or 0.1,
        y = y or 0.1,
        width = width or 0.23,
        currentOption = 1,
        previousMenu = nil,
        aboutToBeClosed = false,
        optionCount = 0,
        options = {},
        panels = {},
        cooldown = 0,
        maxOptions = maxOptions or LayakUI.Settings.MaxOptions
    }
    
    LayakUI.Menus[id] = menu
    LayakUI.Pool[#LayakUI.Pool + 1] = menu
    
    return menu
end

-- Ajouter un bouton au menu
function LayakUI.AddButton(menu, label, description, callback, args)
    if type(menu) == 'string' then menu = LayakUI.Menus[menu] end
    if not menu then return end
    
    menu.optionCount = menu.optionCount + 1
    
    local option = {
        label = label,
        description = description,
        callback = callback,
        args = args
    }
    
    menu.options[menu.optionCount] = option
    
    return option
end

-- Ajouter un séparateur
function LayakUI.AddSeparator(menu, label)
    return LayakUI.AddButton(menu, label or '', nil, function() end)
end

-- Ajouter un slider
function LayakUI.AddSlider(menu, label, description, min, max, value, callback)
    local option = LayakUI.AddButton(menu, label, description)
    option.type = 'slider'
    option.min = min
    option.max = max
    option.value = value
    option.callback = callback
    return option
end

-- Ajouter une checkbox
function LayakUI.AddCheckbox(menu, label, description, checked, callback)
    local option = LayakUI.AddButton(menu, label, description)
    option.type = 'checkbox'
    option.checked = checked
    option.callback = callback
    return option
end

-- Ouvrir un menu
function LayakUI.OpenMenu(id)
    if not LayakUI.Menus[id] then return end
    PlaySoundFrontend(-1, "SELECT", "HUD_FRONTEND_DEFAULT_SOUNDSET", true)
    LayakUI.CurrentMenu = LayakUI.Menus[id]
end

-- Fermer le menu actuel
function LayakUI.CloseMenu()
    if not LayakUI.CurrentMenu then return end
    PlaySoundFrontend(-1, "QUIT", "HUD_FRONTEND_DEFAULT_SOUNDSET", true)
    LayakUI.CurrentMenu.aboutToBeClosed = true
end

-- Dessiner le menu
local function DrawMenu()
    if not LayakUI.CurrentMenu then return end
    
    local menu = LayakUI.CurrentMenu
    local x = menu.x
    local y = menu.y
    local width = menu.width
    
    -- Fond du menu
    DrawRect(x, y, width, 0.1, 
        LayakUI.Settings.BackgroundColor.r, 
        LayakUI.Settings.BackgroundColor.g, 
        LayakUI.Settings.BackgroundColor.b, 
        LayakUI.Settings.BackgroundColor.a
    )
    
    -- Titre
    DrawText2D(menu.title, x, y - 0.03, 0.7, 4, true)
    
    -- Sous-titre
    DrawRect(x, y + 0.04, width, 0.03, 
        LayakUI.Settings.SubTitleBackgroundColor.r, 
        LayakUI.Settings.SubTitleBackgroundColor.g, 
        LayakUI.Settings.SubTitleBackgroundColor.b, 
        LayakUI.Settings.SubTitleBackgroundColor.a
    )
    DrawText2D(menu.subtitle, x, y + 0.03, 0.4, 4, false)
    
    -- Options
    local yOffset = 0.07
    for i = 1, math.min(menu.maxOptions, #menu.options) do
        local option = menu.options[i + menu.currentOption - 1]
        if option then
            if i == 1 and menu.currentOption > 1 then
                DrawText2D("↑", x, y + yOffset, 0.4, 4, false)
            elseif i == menu.maxOptions and (menu.currentOption + menu.maxOptions - 1) < #menu.options then
                DrawText2D("↓", x, y + yOffset, 0.4, 4, false)
            end
            
            local isSelected = (i + menu.currentOption - 1) == menu.currentOption
            local color = isSelected and LayakUI.Settings.SelectableColors or LayakUI.Settings.UnSelectableColors
            
            DrawText2D(option.label, x - width/2 + 0.005, y + yOffset, 0.4, 4, false, color.r, color.g, color.b, color.a)
            
            if option.type == 'slider' then
                -- Dessiner le slider
            elseif option.type == 'checkbox' then
                -- Dessiner la checkbox
            end
            
            yOffset = yOffset + 0.03
        end
    end
    
    -- Description
    if menu.options[menu.currentOption] and menu.options[menu.currentOption].description then
        DrawRect(x, y + yOffset + 0.02, width, 0.04, 0, 0, 0, 200)
        DrawText2D(menu.options[menu.currentOption].description, x, y + yOffset + 0.015, 0.3, 4, false)
    end
end

-- Gestion des contrôles
local function ProcessMenuControls()
    if not LayakUI.CurrentMenu or LayakUI.CurrentMenu.cooldown > GetGameTimer() then return end
    
    local menu = LayakUI.CurrentMenu
    
    if IsControlJustPressed(0, 172) then -- Flèche haut
        PlaySoundFrontend(-1, "NAV_UP_DOWN", "HUD_FRONTEND_DEFAULT_SOUNDSET", true)
        menu.currentOption = menu.currentOption > 1 and menu.currentOption - 1 or #menu.options
        menu.cooldown = GetGameTimer() + 200
    elseif IsControlJustPressed(0, 173) then -- Flèche bas
        PlaySoundFrontend(-1, "NAV_UP_DOWN", "HUD_FRONTEND_DEFAULT_SOUNDSET", true)
        menu.currentOption = menu.currentOption < #menu.options and menu.currentOption + 1 or 1
        menu.cooldown = GetGameTimer() + 200
    elseif IsControlJustPressed(0, 201) then -- Sélectionner
        local option = menu.options[menu.currentOption]
        if option and option.callback then
            option.callback(option.args)
        end
    elseif IsControlJustPressed(0, 177) then -- Retour
        LayakUI.CloseMenu()
    end
end

-- Boucle principale
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        ProcessMenuControls()
        DrawMenu()
    end
end)

 ```lua
-- Fonction pour dessiner du texte en 2D
function DrawText2D(text, x, y, scale, font, center, r, g, b, a)
    SetTextFont(font or 0)
    SetTextScale(scale, scale)
    SetTextColour(r or 255, g or 255, b or 255, a or 255)
    SetTextEntry("STRING")
    AddTextComponentString(text)
    if center then
        DrawText(x, y)
    else
        DrawText(x - 0.5, y - 0.5)
    end
end

-- Fonction pour dessiner un rectangle
function DrawRect(x, y, width, height, r, g, b, a)
    local w = width / 2
    local h = height / 2
    DrawRect(x, y, w, h, r, g, b, a)
end

-- Fonction pour gérer les événements de menu
AddEventHandler('onResourceStop', function(resourceName)
    if resourceName == GetCurrentResourceName() then
        LayakUI.CloseMenu()
    end
end)

-- Exemple d'utilisation
local mainMenu = LayakUI.CreateMenu('main', 'Menu Principal', 'Sélectionnez une option')
LayakUI.AddButton(mainMenu, 'Option 1', 'Description de l\'option 1', function() print('Option 1 sélectionnée') end)
LayakUI.AddButton(mainMenu, 'Option 2', 'Description de l\'option 2', function() print('Option 2 sélectionnée') end)
LayakUI.OpenMenu('main')
``` ```lua
-- Fonction pour ajouter un panneau au menu
function LayakUI.AddPanel(menu, label, description, callback)
    local option = LayakUI.AddButton(menu, label, description)
    option.type = 'panel'
    option.callback = callback
    return option
end

-- Fonction pour gérer les panneaux
function LayakUI.OpenPanel(menu, panelId)
    if not menu.panels[panelId] then return end
    menu.currentPanel = menu.panels[panelId]
end

-- Exemple d'utilisation des panneaux
local settingsMenu = LayakUI.CreateMenu('settings', 'Paramètres', 'Ajustez vos préférences')
LayakUI.AddPanel(settingsMenu, 'Panneau Audio', 'Ajustez le volume et les paramètres audio', function() 
    print('Panneau Audio ouvert') 
end)
LayakUI.AddPanel(settingsMenu, 'Panneau Graphique', 'Ajustez les paramètres graphiques', function() 
    print('Panneau Graphique ouvert') 
end)

-- Ajout d'un bouton pour ouvrir le menu des paramètres
LayakUI.AddButton(mainMenu, 'Paramètres', 'Accédez aux paramètres', function() 
    LayakUI.OpenMenu('settings') 
end)

-- Boucle principale mise à jour pour gérer les panneaux
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        ProcessMenuControls()
        DrawMenu()
        
        if LayakUI.CurrentMenu and LayakUI.CurrentMenu.currentPanel then
            -- Dessiner le contenu du panneau ici
            DrawText2D(LayakUI.CurrentMenu.currentPanel.title, LayakUI.CurrentMenu.x, LayakUI.CurrentMenu.y + 0.1, 0.5, 4, true)
            -- Ajouter d'autres éléments de panneau ici
        end
    end
end)
-- Fonction pour ajouter un bouton de retour dans les panneaux
function LayakUI.AddBackButton(menu, label, description)
    return LayakUI.AddButton(menu, label, description, function()
        LayakUI.CloseMenu()
    end)
end

-- Exemple d'utilisation du bouton de retour dans un panneau
LayakUI.AddBackButton(settingsMenu, 'Retour', 'Retour au menu principal')

-- Mise à jour de la boucle principale pour gérer le retour
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        ProcessMenuControls()
        DrawMenu()
        
        if LayakUI.CurrentMenu and LayakUI.CurrentMenu.currentPanel then
            -- Dessiner le contenu du panneau ici
            DrawText2D(LayakUI.CurrentMenu.currentPanel.title, LayakUI.CurrentMenu.x, LayakUI.CurrentMenu.y + 0.1, 0.5, 4, true)
            -- Ajouter d'autres éléments de panneau ici
        end
    end
end)

-- Fonction pour ajouter un bouton de confirmation
function LayakUI.AddConfirmButton(menu, label, description, callback)
    return LayakUI.AddButton(menu, label, description, function()
        if callback then callback() end
        LayakUI.CloseMenu()
    end)
end

-- Exemple d'utilisation du bouton de confirmation
LayakUI.AddConfirmButton(settingsMenu, 'Confirmer', 'Confirmez vos choix', function()
    print('Choix confirmé')
end)

-- Ajout d'un bouton pour ouvrir un sous-menu
local subMenu = LayakUI.CreateMenu('subMenu', 'Sous-menu', 'Sélectionnez une option')
LayakUI.AddButton(subMenu, 'Sous-option 1', 'Description de la sous-option 1', function() print('Sous-option 1 sélectionnée') end)
LayakUI.AddButton(subMenu, 'Sous-option 2', 'Description de la sous-option 2', function() print('Sous-option 2 sélectionnée') end)

-- Ajout d'un bouton pour ouvrir le sous-menu depuis le menu principal
LayakUI.AddButton(mainMenu, 'Ouvrir Sous-menu', 'Accédez au sous-menu', function() 
    LayakUI.OpenMenu('subMenu') 
end)

-- Boucle principale mise à jour pour gérer les sous-menus
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        ProcessMenuControls()
        DrawMenu()
        
        if LayakUI.CurrentMenu and LayakUI.CurrentMenu.currentPanel then
            -- Dessiner le contenu du panneau ici
            DrawText2D(LayakUI.CurrentMenu.currentPanel.title, LayakUI.CurrentMenu.x, LayakUI.CurrentMenu.y + 0.1, 0.5, 4, true)
            -- Ajouter d'autres éléments de panneau ici
        end
    end
end)
-- Fonction pour ajouter un bouton de chargement
function LayakUI.AddLoadingButton(menu, label, description, loadingCallback)
    local option = LayakUI.AddButton(menu, label, description)
    option.type = 'loading'
    option.loadingCallback = loadingCallback
    return option
end

-- Exemple d'utilisation du bouton de chargement
LayakUI.AddLoadingButton(mainMenu, 'Charger Données', 'Chargez les données, veuillez patienter...', function()
    print('Chargement des données...')
    Citizen.Wait(3000) -- Simule un chargement de 3 secondes
    print('Données chargées avec succès!')
end)

-- Mise à jour de la boucle principale pour gérer les boutons de chargement
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        ProcessMenuControls()
        DrawMenu()
        
        if LayakUI.CurrentMenu then
            for i, option in ipairs(LayakUI.CurrentMenu.options) do
                if option.type == 'loading' and option.loadingCallback then
                    option.loadingCallback()
                end
            end
        end
    end
end)

-- Fonction pour ajouter un bouton de sélection multiple
function LayakUI.AddMultiSelectButton(menu, label, description, options, callback)
    local option = LayakUI.AddButton(menu, label, description)
    option.type = 'multiSelect'
    option.selectedOptions = {}
    option.options = options
    option.callback = callback
    return option
end

-- Exemple d'utilisation du bouton de sélection multiple
LayakUI.AddMultiSelectButton(mainMenu, 'Sélectionner Options', 'Sélectionnez plusieurs options', {'Option A', 'Option B', 'Option C'}, function(selected)
    print('Options sélectionnées: ' .. table.concat(selected, ', '))
end)

-- Mise à jour de la boucle principale pour gérer les boutons de sélection multiple
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        ProcessMenuControls()
        DrawMenu()
        
        if LayakUI.CurrentMenu then
            for i, option in ipairs(LayakUI.CurrentMenu.options) do
                if option.type == 'multiSelect' then
                    -- Gérer la sélection des options
                    for _, opt in ipairs(option.options) do
                        if IsControlJustPressed(0, 201) then -- Sélectionner
                            option.selectedOptions[opt] = not option.selectedOptions[opt]
                        end
                    end
                    option.callback(option.selectedOptions)
                end
            end
        end
    end
end)
-- Fonction pour ajouter un bouton de recherche
function LayakUI.AddSearchButton(menu, label, description, searchCallback)
    local option = LayakUI.AddButton(menu, label, description)
    option.type = 'search'
    option.searchCallback = searchCallback
    return option
end

-- Exemple d'utilisation du bouton de recherche
LayakUI.AddSearchButton(mainMenu, 'Rechercher', 'Recherchez des éléments', function(query)
    print('Recherche pour: ' .. query)
    -- Implémentez la logique de recherche ici
end)

-- Mise à jour de la boucle principale pour gérer les boutons de recherche
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        ProcessMenuControls()
        DrawMenu()
        
        if LayakUI.CurrentMenu then
            for i, option in ipairs(LayakUI.CurrentMenu.options) do
                if option.type == 'search' and option.searchCallback then
                    -- Implémentez la logique pour obtenir la saisie de l'utilisateur
                    local userInput = 'exemple' -- Remplacez ceci par la saisie réelle
                    option.searchCallback(userInput)
                end
            end
        end
    end
end)

-- Fonction pour ajouter un bouton de tri
function LayakUI.AddSortButton(menu, label, description, sortCallback)
    local option = LayakUI.AddButton(menu, label, description)
    option.type = 'sort'
    option.sortCallback = sortCallback
    return option
end

-- Exemple d'utilisation du bouton de tri
LayakUI.AddSortButton(mainMenu, 'Trier', 'Trier les éléments', function(order)
    print('Tri des éléments par: ' .. order)
    -- Implémentez la logique de tri ici
end)

-- Mise à jour de la boucle principale pour gérer les boutons de tri
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        ProcessMenuControls()
        DrawMenu()
        
        if LayakUI.CurrentMenu then
            for i, option in ipairs(LayakUI.CurrentMenu.options) do
                if option.type == 'sort' and option.sortCallback then
                    -- Implémentez la logique pour trier les éléments
                    local sortOrder = 'asc' -- Remplacez ceci par l'ordre réel
                    option.sortCallback(sortOrder)
                end
            end
        end
    end
end)
-- Fonction pour ajouter un bouton de filtre
function LayakUI.AddFilterButton(menu, label, description, filterCallback)
    local option = LayakUI.AddButton(menu, label, description)
    option.type = 'filter'
    option.filterCallback = filterCallback
    return option
end

-- Exemple d'utilisation du bouton de filtre
LayakUI.AddFilterButton(mainMenu, 'Filtrer', 'Filtrer les éléments', function(criteria)
    print('Filtrage des éléments par: ' .. criteria)
    -- Implémentez la logique de filtrage ici
end)

-- Mise à jour de la boucle principale pour gérer les boutons de filtre
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        ProcessMenuControls()
        DrawMenu()
        
        if LayakUI.CurrentMenu then
            for i, option in ipairs(LayakUI.CurrentMenu.options) do
                if option.type == 'filter' and option.filterCallback then
                    -- Implémentez la logique pour obtenir les critères de filtrage de l'utilisateur
                    local filterCriteria = 'exemple' -- Remplacez ceci par le critère réel
                    option.filterCallback(filterCriteria)
                end
            end
        end
    end
end)

-- Fonction pour ajouter un bouton d'exportation
function LayakUI.AddExportButton(menu, label, description, exportCallback)
    local option = LayakUI.AddButton(menu, label, description)
    option.type = 'export'
    option.exportCallback = exportCallback
    return option
end

-- Exemple d'utilisation du bouton d'exportation
LayakUI.AddExportButton(mainMenu, 'Exporter', 'Exporter les données', function(format)
    print('Exportation des données au format: ' .. format)
    -- Implémentez la logique d'exportation ici
end)

-- Mise à jour de la boucle principale pour gérer les boutons d'exportation
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        ProcessMenuControls()
        DrawMenu()
        
        if LayakUI.CurrentMenu then
            for i, option in ipairs(LayakUI.CurrentMenu.options) do
                if option.type == 'export' and option.exportCallback then
                    -- Implémentez la logique pour obtenir le format d'exportation de l'utilisateur
                    local exportFormat = 'CSV' -- Remplacez ceci par le format réel
                    option.exportCallback(exportFormat)
                end
            end
        end
    end
end)

-- Fonction pour ajouter un bouton d'importation
function LayakUI.AddImportButton(menu, label, description, importCallback)
    local option = LayakUI.AddButton(menu, label, description)
    option.type = 'import'
    option.importCallback = importCallback
    return option
end

-- Exemple d'utilisation du bouton d'importation
LayakUI.AddImportButton(mainMenu, 'Importer', 'Importer des données', function(file)
    print('Importation des données depuis le fichier: ' .. file)
    -- Implémentez la logique d'importation ici
end)

-- Mise à jour de la boucle principale pour gérer les boutons d'importation
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        ProcessMenuControls()
        DrawMenu()
        
        if LayakUI.CurrentMenu then
            for i, option in ipairs(LayakUI.CurrentMenu.options) do
                if option.type == 'import' and option.importCallback then
                    -- Implémentez la logique pour obtenir le fichier d'importation de l'utilisateur
                    local importFile = 'data.json' -- Remplacez ceci par le fichier réel
                    option.importCallback(importFile)
                end
            end
        end
    end
end)
-- Fonction pour ajouter un bouton de réinitialisation
function LayakUI.AddResetButton(menu, label, description, resetCallback)
    local option = LayakUI.AddButton(menu, label, description)
    option.type = 'reset'
    option.resetCallback = resetCallback
    return option
end

-- Exemple d'utilisation du bouton de réinitialisation
LayakUI.AddResetButton(mainMenu, 'Réinitialiser', 'Réinitialisez les paramètres', function()
    print('Paramètres réinitialisés aux valeurs par défaut.')
    -- Implémentez la logique de réinitialisation ici
end)

-- Mise à jour de la boucle principale pour gérer les boutons de réinitialisation
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        ProcessMenuControls()
        DrawMenu()
        
        if LayakUI.CurrentMenu then
            for i, option in ipairs(LayakUI.CurrentMenu.options) do
                if option.type == 'reset' and option.resetCallback then
                    option.resetCallback()
                end
            end
        end
    end
end)

-- Fonction pour ajouter un bouton d'aide
function LayakUI.AddHelpButton(menu, label, description, helpCallback)
    local option = LayakUI.AddButton(menu, label, description)
    option.type = 'help'
    option.helpCallback = helpCallback
    return option
end

-- Exemple d'utilisation du bouton d'aide
LayakUI.AddHelpButton(mainMenu, 'Aide', 'Obtenez de l\'aide sur l\'utilisation du menu', function()
    print('Voici quelques conseils pour utiliser le menu...')
    -- Implémentez la logique d'aide ici
end)

-- Mise à jour de la boucle principale pour gérer les boutons d'aide
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        ProcessMenuControls()
        DrawMenu()
        
        if LayakUI.CurrentMenu then
            for i, option in ipairs(LayakUI.CurrentMenu.options) do
                if option.type == 'help' and option.helpCallback then
                    option.helpCallback()
                end
            end
        end
    end
end)

-- Fonction pour ajouter un bouton de partage
function LayakUI.AddShareButton(menu, label, description, shareCallback)
    local option = LayakUI.AddButton(menu, label, description)
    option.type = 'share'
    option.shareCallback = shareCallback
    return option
end

-- Exemple d'utilisation du bouton de partage
LayakUI.AddShareButton(mainMenu, 'Partager', 'Partagez vos paramètres', function()
    print('Paramètres partagés avec succès!')
    -- Implémentez la logique de partage ici
end)

-- Mise à jour de la boucle principale pour gérer les boutons de partage
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        ProcessMenuControls()
        DrawMenu()
        
        if LayakUI.CurrentMenu then
            for i, option in ipairs(LayakUI.CurrentMenu.options) do
                if option.type == 'share' and option.shareCallback then
                    option.shareCallback()
                end
            end
        end
    end
end)
-- Fonction pour ajouter un bouton de notification
function LayakUI.AddNotificationButton(menu, label, description, notificationCallback)
    local option = LayakUI.AddButton(menu, label, description)
    option.type = 'notification'
    option.notificationCallback = notificationCallback
    return option
end

-- Exemple d'utilisation du bouton de notification
LayakUI.AddNotificationButton(mainMenu, 'Notifier', 'Recevez une notification', function()
    print('Notification envoyée avec succès!')
    -- Implémentez la logique de notification ici
end)

-- Mise à jour de la boucle principale pour gérer les boutons de notification
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        ProcessMenuControls()
        DrawMenu()
        
        if LayakUI.CurrentMenu then
            for i, option in ipairs(LayakUI.CurrentMenu.options) do
                if option.type == 'notification' and option.notificationCallback then
                    option.notificationCallback()
                end
            end
        end
    end
end)

-- Fonction pour ajouter un bouton de configuration avancée
function LayakUI.AddAdvancedConfigButton(menu, label, description, configCallback)
    local option = LayakUI.AddButton(menu, label, description)
    option.type = 'advancedConfig'
    option.configCallback = configCallback
    return option
end

-- Exemple d'utilisation du bouton de configuration avancée
LayakUI.AddAdvancedConfigButton(mainMenu, 'Configuration Avancée', 'Accédez aux paramètres avancés', function()
    print('Accès aux paramètres avancés accordé.')
    -- Implémentez la logique de configuration avancée ici
end)

-- Mise à jour de la boucle principale pour gérer les boutons de configuration avancée
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        ProcessMenuControls()
        DrawMenu()
        
        if LayakUI.CurrentMenu then
            for i, option in ipairs(LayakUI.CurrentMenu.options) do
                if option.type == 'advancedConfig' and option.configCallback then
                    option.configCallback()
                end
            end
        end
    end
end)

-- Fonction pour ajouter un bouton de mise à jour
function LayakUI.AddUpdateButton(menu, label, description, updateCallback)
    local option = LayakUI.AddButton(menu, label, description)
    option.type = 'update'
    option.updateCallback = updateCallback
    return option
end

-- Exemple d'utilisation du bouton de mise à jour
LayakUI.AddUpdateButton(mainMenu, 'Mettre à Jour', 'Mettez à jour le système', function()
    print('Mise à jour en cours...')
    -- Implémentez la logique de mise à jour ici
end)

-- Mise à jour de la boucle principale pour gérer les boutons de mise à jour
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        ProcessMenuControls()
        DrawMenu()
        
        if LayakUI.CurrentMenu then
            for i, option in ipairs(LayakUI.CurrentMenu.options) do
                if option.type == 'update' and option.updateCallback then
                    option.updateCallback()
                end
            end
        end
    end
end)
-- Fonction pour ajouter un bouton de déconnexion
function LayakUI.AddLogoutButton(menu, label, description, logoutCallback)
    local option = LayakUI.AddButton(menu, label, description)
    option.type = 'logout'
    option.logoutCallback = logoutCallback
    return option
end

-- Exemple d'utilisation du bouton de déconnexion
LayakUI.AddLogoutButton(mainMenu, 'Déconnexion', 'Déconnectez-vous du système', function()
    print('Déconnexion réussie!')
    -- Implémentez la logique de déconnexion ici
end)

-- Mise à jour de la boucle principale pour gérer les boutons de déconnexion
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        ProcessMenuControls()
        DrawMenu()
        
        if LayakUI.CurrentMenu then
            for i, option in ipairs(LayakUI.CurrentMenu.options) do
                if option.type == 'logout' and option.logoutCallback then
                    option.logoutCallback()
                end
            end
        end
    end
end)

-- Fonction pour ajouter un bouton de retour à l'accueil
function LayakUI.AddHomeButton(menu, label, description, homeCallback)
    local option = LayakUI.AddButton(menu, label, description)
    option.type = 'home'
    option.homeCallback = homeCallback
    return option
end

-- Exemple d'utilisation du bouton de retour à l'accueil
LayakUI.AddHomeButton(mainMenu, 'Accueil', 'Retournez à l\'accueil', function()
    print('Retour à l\'accueil effectué!')
    -- Implémentez la logique pour retourner à l'accueil ici
end)

-- Mise à jour de la boucle principale pour gérer les boutons de retour à l'accueil
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        ProcessMenuControls()
        DrawMenu()
        
        if LayakUI.CurrentMenu then
            for i, option in ipairs(LayakUI.CurrentMenu.options) do
                if option.type == 'home' and option.homeCallback then
                    option.homeCallback()
                end
            end
        end
    end
end)

-- Fonction pour ajouter un bouton de feedback
function LayakUI.AddFeedbackButton(menu, label, description, feedbackCallback)
    local option = LayakUI.AddButton(menu, label, description)
    option.type = 'feedback'
    option.feedbackCallback = feedbackCallback
    return option
end

-- Exemple d'utilisation du bouton de feedback
LayakUI.AddFeedbackButton(mainMenu, 'Feedback', 'Donnez votre avis', function()
    print('Merci pour votre feedback!')
    -- Implémentez la logique de feedback ici
end)

-- Mise à jour de la boucle principale pour gérer les boutons de feedback
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        ProcessMenuControls()
        DrawMenu()
        
        if LayakUI.CurrentMenu then
            for i, option in ipairs(LayakUI.CurrentMenu.options) do
                if option.type == 'feedback' and option.feedbackCallback then
                    option.feedbackCallback()
                end
            end
        end
    end
end)
-- Fonction pour ajouter un bouton de personnalisation
function LayakUI.AddCustomizationButton(menu, label, description, customizationCallback)
    local option = LayakUI.AddButton(menu, label, description)
    option.type = 'customization'
    option.customizationCallback = customizationCallback
    return option
end

-- Exemple d'utilisation du bouton de personnalisation
LayakUI.AddCustomizationButton(mainMenu, 'Personnaliser', 'Personnalisez votre expérience', function()
    print('Personnalisation en cours...')
    -- Implémentez la logique de personnalisation ici
end)

-- Mise à jour de la boucle principale pour gérer les boutons de personnalisation
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        ProcessMenuControls()
        DrawMenu()
        
        if LayakUI.CurrentMenu then
            for i, option in ipairs(LayakUI.CurrentMenu.options) do
                if option.type == 'customization' and option.customizationCallback then
                    option.customizationCallback()
                end
            end
        end
    end
end)

-- Fonction pour ajouter un bouton de rapport
function LayakUI.AddReportButton(menu, label, description, reportCallback)
    local option = LayakUI.AddButton(menu, label, description)
    option.type = 'report'
    option.reportCallback = reportCallback
    return option
end

-- Exemple d'utilisation du bouton de rapport
LayakUI.AddReportButton(mainMenu, 'Rapporter', 'Rapportez un problème', function()
    print('Rapport envoyé avec succès!')
    -- Implémentez la logique de rapport ici
end)

-- Mise à jour de la boucle principale pour gérer les boutons de rapport
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        ProcessMenuControls()
        DrawMenu()
        
        if LayakUI.CurrentMenu then
            for i, option in ipairs(LayakUI.CurrentMenu.options) do
                if option.type == 'report' and option.reportCallback then
                    option.reportCallback()
                end
            end
        end
    end
end)

-- Fonction pour ajouter un bouton de vérification
function LayakUI.AddCheckButton(menu, label, description, checkCallback)
    local option = LayakUI.AddButton(menu, label, description)
    option.type = 'check'
    option.checkCallback = checkCallback
    return option
end

-- Exemple d'utilisation du bouton de vérification
LayakUI.AddCheckButton(mainMenu, 'Vérifier', 'Vérifiez votre statut', function()
    print('Vérification effectuée avec succès!')
    -- Implémentez la logique de vérification ici
end)

-- Mise à jour de la boucle principale pour gérer les boutons de vérification
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        ProcessMenuControls()
        DrawMenu()
        
        if LayakUI.CurrentMenu then
            for i, option in ipairs(LayakUI.CurrentMenu.options) do
                if option.type == 'check' and option.checkCallback then
                    option.checkCallback()
                end
            end
        end
    end
end)
-- Fonction pour ajouter un bouton de confirmation d'action
function LayakUI.AddActionConfirmButton(menu, label, description, actionCallback)
    local option = LayakUI.AddButton(menu, label, description)
    option.type = 'actionConfirm'
    option.actionCallback = actionCallback
    return option
end

-- Exemple d'utilisation du bouton de confirmation d'action
LayakUI.AddActionConfirmButton(mainMenu, 'Confirmer Action', 'Confirmez l\'action', function()
    print('Action confirmée avec succès!')
    -- Implémentez la logique de confirmation d'action ici
end)

-- Mise à jour de la boucle principale pour gérer les boutons de confirmation d'action
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        ProcessMenuControls()
        DrawMenu()
        
        if LayakUI.CurrentMenu then
            for i, option in ipairs(LayakUI.CurrentMenu.options) do
                if option.type == 'actionConfirm' and option.actionCallback then
                    option.actionCallback()
                end
            end
        end
    end
end)

-- Fonction pour ajouter un bouton de sauvegarde
function LayakUI.AddSaveButton(menu, label, description, saveCallback)
    local option = LayakUI.AddButton(menu, label, description)
    option.type = 'save'
    option.saveCallback = saveCallback
    return option
end

-- Exemple d'utilisation du bouton de sauvegarde
LayakUI.AddSaveButton(mainMenu, 'Sauvegarder', 'Sauvegardez vos paramètres', function()
    print('Paramètres sauvegardés avec succès!')
    -- Implémentez la logique de sauvegarde ici
end)

-- Mise à jour de la boucle principale pour gérer les boutons de sauvegarde
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        ProcessMenuControls()
        DrawMenu()
        
        if LayakUI.CurrentMenu then
            for i, option in ipairs(LayakUI.CurrentMenu.options) do
                if option.type == 'save' and option.saveCallback then
                    option.saveCallback()
                end
            end
        end
    end
end)

-- Fonction pour ajouter un bouton de chargement
function LayakUI.AddLoadButton(menu, label, description, loadCallback)
    local option = LayakUI.AddButton(menu, label, description)
    option.type = 'load'
    option.loadCallback = loadCallback
    return option
end

-- Exemple d'utilisation du bouton de chargement
LayakUI.AddLoadButton(mainMenu, 'Charger', 'Chargez vos paramètres', function()
    print('Paramètres chargés avec succès!')
    -- Implémentez la logique de chargement ici
end)

-- Mise à jour de la boucle principale pour gérer les boutons de chargement
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        ProcessMenuControls()
        DrawMenu()
        
        if LayakUI.CurrentMenu then
            for i, option in ipairs(LayakUI.CurrentMenu.options) do
                if option.type == 'load' and option.loadCallback then
                    option.loadCallback()
                end
            end
        end
    end
end)

-- Fonction pour ajouter un bouton de réinitialisation des paramètres
function LayakUI.AddResetSettingsButton(menu, label, description, resetCallback)
    local option = LayakUI.AddButton(menu, label, description)
    option.type = 'resetSettings'
    option.resetCallback = resetCallback
    return option
end

-- Exemple d'utilisation du bouton de réinitialisation des paramètres
LayakUI.AddResetSettingsButton(mainMenu, 'Réinitialiser Paramètres', 'Réinitialisez tous les paramètres', function()
    print('Tous les paramètres réinitialisés aux valeurs par défaut.')
    -- Implémentez la logique de réinitialisation des paramètres ici
end)

-- Mise à jour de la boucle principale pour gérer les boutons de réinitialisation des paramètres
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        ProcessMenuControls()
        DrawMenu()
        
        if LayakUI.CurrentMenu then
            for i, option in ipairs(LayakUI.CurrentMenu.options) do
                if option.type == 'resetSettings' and option.resetCallback then
                    option.resetCallback()
                end
            end
        end
    end
end)
-- Fonction pour ajouter un bouton de vérification des mises à jour
function LayakUI.AddCheckUpdateButton(menu, label, description, checkUpdateCallback)
    local option = LayakUI.AddButton(menu, label, description)
    option.type = 'checkUpdate'
    option.checkUpdateCallback = checkUpdateCallback
    return option
end

-- Exemple d'utilisation du bouton de vérification des mises à jour
LayakUI.AddCheckUpdateButton(mainMenu, 'Vérifier Mises à Jour', 'Vérifiez si des mises à jour sont disponibles', function()
    print('Vérification des mises à jour en cours...')
    -- Implémentez la logique de vérification des mises à jour ici
end)

-- Mise à jour de la boucle principale pour gérer les boutons de vérification des mises à jour
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        ProcessMenuControls()
        DrawMenu()
        
        if LayakUI.CurrentMenu then
            for i, option in ipairs(LayakUI.CurrentMenu.options) do
                if option.type == 'checkUpdate' and option.checkUpdateCallback then
                    option.checkUpdateCallback()
                end
            end
        end
    end
end)

-- Fonction pour ajouter un bouton de rapport d'erreur
function LayakUI.AddErrorReportButton(menu, label, description, errorReportCallback)
    local option = LayakUI.AddButton(menu, label, description)
    option.type = 'errorReport'
    option.errorReportCallback = errorReportCallback
    return option
end

-- Exemple d'utilisation du bouton de rapport d'erreur
LayakUI.AddErrorReportButton(mainMenu, 'Rapporter Erreur', 'Signalez un problème rencontré', function()
    print('Erreur signalée avec succès!')
    -- Implémentez la logique de rapport d'erreur ici
end)

-- Mise à jour de la boucle principale pour gérer les boutons de rapport d'erreur
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        ProcessMenuControls()
        DrawMenu()
        
        if LayakUI.CurrentMenu then
            for i, option in ipairs(LayakUI.CurrentMenu.options) do
                if option.type == 'errorReport' and option.errorReportCallback then
                    option.errorReportCallback()
                end
            end
        end
    end
end)

-- Fonction pour ajouter un bouton de retour à la dernière action
function LayakUI.AddUndoButton(menu, label, description, undoCallback)
    local option = LayakUI.AddButton(menu, label, description)
    option.type = 'undo'
    option.undoCallback = undoCallback
    return option
end

-- Exemple d'utilisation du bouton de retour à la dernière action
LayakUI.AddUndoButton(mainMenu, 'Annuler', 'Annulez la dernière action', function()
    print('Dernière action annulée!')
    -- Implémentez la logique d'annulation ici
end)

-- Mise à jour de la boucle principale pour gérer les boutons d'annulation
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        ProcessMenuControls()
        DrawMenu()
        
        if LayakUI.CurrentMenu then
            for i, option in ipairs(LayakUI.CurrentMenu.options) do
                if option.type == 'undo' and option.undoCallback then
                    option.undoCallback()
                end
            end
        end
    end
end)
-- Fonction pour ajouter un bouton de confirmation de suppression
function LayakUI.AddDeleteConfirmButton(menu, label, description, deleteCallback)
    local option = LayakUI.AddButton(menu, label, description)
    option.type = 'deleteConfirm'
    option.deleteCallback = deleteCallback
    return option
end

-- Exemple d'utilisation du bouton de confirmation de suppression
LayakUI.AddDeleteConfirmButton(mainMenu, 'Confirmer Suppression', 'Confirmez la suppression', function()
    print('Suppression confirmée avec succès!')
    -- Implémentez la logique de suppression ici
end)

-- Mise à jour de la boucle principale pour gérer les boutons de confirmation de suppression
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        ProcessMenuControls()
        DrawMenu()
        
        if LayakUI.CurrentMenu then
            for i, option in ipairs(LayakUI.CurrentMenu.options) do
                if option.type == 'deleteConfirm' and option.deleteCallback then
                    option.deleteCallback()
                end
            end
        end
    end
end)

-- Fonction pour ajouter un bouton de révision
function LayakUI.AddReviewButton(menu, label, description, reviewCallback)
    local option = LayakUI.AddButton(menu, label, description)
    option.type = 'review'
    option.reviewCallback = reviewCallback
    return option
end

-- Exemple d'utilisation du bouton de révision
LayakUI.AddReviewButton(mainMenu, 'Réviser', 'Révisez vos choix', function()
    print('Révision effectuée avec succès!')
    -- Implémentez la logique de révision ici
end)

-- Mise à jour de la boucle principale pour gérer les boutons de révision
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        ProcessMenuControls()
        DrawMenu()
        
        if LayakUI.CurrentMenu then
            for i, option in ipairs(LayakUI.CurrentMenu.options) do
                if option.type == 'review' and option.reviewCallback then
                    option.reviewCallback()
                end
            end
        end
    end
end)

-- Fonction pour ajouter un bouton de partage de feedback
function LayakUI.AddShareFeedbackButton(menu, label, description, shareFeedbackCallback)
    local option = LayakUI.AddButton(menu, label, description)
    option.type = 'shareFeedback'
    option.shareFeedbackCallback = shareFeedbackCallback
    return option
end

-- Exemple d'utilisation du bouton de partage de feedback
LayakUI.AddShareFeedbackButton(mainMenu, 'Partager Feedback', 'Partagez votre feedback', function()
    print('Feedback partagé avec succès!')
    -- Implémentez la logique de partage de feedback ici
end)

-- Mise à jour de la boucle principale pour gérer les boutons de partage de feedback
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        ProcessMenuControls()
        DrawMenu()
        
        if LayakUI.CurrentMenu then
            for i, option in ipairs(LayakUI.CurrentMenu.options) do
                if option.type == 'shareFeedback' and option.shareFeedbackCallback then
                    option.shareFeedbackCallback()
                end
            end
        end
    end
end)
-- Fonction pour ajouter un bouton de configuration de thème
function LayakUI.AddThemeConfigButton(menu, label, description, themeConfigCallback)
    local option = LayakUI.AddButton(menu, label, description)
    option.type = 'themeConfig'
    option.themeConfigCallback = themeConfigCallback
    return option
end

-- Exemple d'utilisation du bouton de configuration de thème
LayakUI.AddThemeConfigButton(mainMenu, 'Configurer Thème', 'Personnalisez le thème du menu', function()
    print('Thème configuré avec succès!')
    -- Implémentez la logique de configuration de thème ici
end)

-- Mise à jour de la boucle principale pour gérer les boutons de configuration de thème
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        ProcessMenuControls()
        DrawMenu()
        
        if LayakUI.CurrentMenu then
            for i, option in ipairs(LayakUI.CurrentMenu.options) do
                if option.type == 'themeConfig' and option.themeConfigCallback then
                    option.themeConfigCallback()
                end
            end
        end
    end
end)

-- Fonction pour ajouter un bouton de gestion des utilisateurs
function LayakUI.AddUser ManagementButton(menu, label, description, userManagementCallback)
    local option = LayakUI.AddButton(menu, label, description)
    option.type = 'userManagement'
    option.userManagementCallback = userManagementCallback
    return option
end

-- Exemple d'utilisation du bouton de gestion des utilisateurs
LayakUI.AddUser ManagementButton(mainMenu, 'Gérer Utilisateurs', 'Gérez les utilisateurs du système', function()
    print('Gestion des utilisateurs ouverte!')
    -- Implémentez la logique de gestion des utilisateurs ici
end)

-- Mise à jour de la boucle principale pour gérer les boutons de gestion des utilisateurs
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        ProcessMenuControls()
        DrawMenu()
        
        if LayakUI.CurrentMenu then
            for i, option in ipairs(LayakUI.CurrentMenu.options) do
                if option.type == 'userManagement' and option.userManagementCallback then
                    option.userManagementCallback()
                end
            end
        end
    end
end)

-- Fonction pour ajouter un bouton de gestion des permissions
function LayakUI.AddPermissionManagementButton(menu, label, description, permissionManagementCallback)
    local option = LayakUI.AddButton(menu, label, description)
    option.type = 'permissionManagement'
    option.permissionManagementCallback = permissionManagementCallback
    return option
end

-- Exemple d'utilisation du bouton de gestion des permissions
LayakUI.AddPermissionManagementButton(mainMenu, 'Gérer Permissions', 'Gérez les permissions des utilisateurs', function()
    print('Gestion des permissions ouverte!')
    -- Implémentez la logique de gestion des permissions ici
end)

-- Mise à jour de la boucle principale pour gérer les boutons de gestion des permissions
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        ProcessMenuControls()
        DrawMenu()
        
        if LayakUI.CurrentMenu then
            for i, option in ipairs(LayakUI.CurrentMenu.options) do
                if option.type == 'permissionManagement' and option.permissionManagementCallback then
                    option.permissionManagementCallback()
                end
            end
        end
    end
end)

-- Fonction pour ajouter un bouton de gestion des rapports
function LayakUI.AddReportManagementButton(menu, label, description, reportManagementCallback)
    local option = LayakUI.AddButton(menu, label, description)
    option.type = 'reportManagement'
    option.reportManagementCallback = reportManagementCallback
    return option
end

-- Exemple d'utilisation du bouton de gestion des rapports
LayakUI.AddReportManagementButton(mainMenu, 'Gérer Rapports', 'Gérez les rapports des utilisateurs', function()
    print('Gestion des rapports ouverte!')
    -- Implémentez la logique de gestion des rapports ici
end)

-- Mise à jour de la boucle principale pour gérer les boutons de gestion des rapports
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        ProcessMenuControls()
        DrawMenu()
        
        if LayakUI.CurrentMenu then
            for i, option in ipairs(LayakUI.CurrentMenu.options) do
                if option.type == 'reportManagement' and option.reportManagementCallback then
                    option.reportManagementCallback()
                end
            end
        end
    end
end)
-- Fonction pour ajouter un bouton de gestion des sessions
function LayakUI.AddSessionManagementButton(menu, label, description, sessionManagementCallback)
    local option = LayakUI.AddButton(menu, label, description)
    option.type = 'sessionManagement'
    option.sessionManagementCallback = sessionManagementCallback
    return option
end

-- Exemple d'utilisation du bouton de gestion des sessions
LayakUI.AddSessionManagementButton(mainMenu, 'Gérer Sessions', 'Gérez les sessions des utilisateurs', function()
    print('Gestion des sessions ouverte!')
    -- Implémentez la logique de gestion des sessions ici
end)

-- Mise à jour de la boucle principale pour gérer les boutons de gestion des sessions
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        ProcessMenuControls()
        DrawMenu()
        
        if LayakUI.CurrentMenu then
            for i, option in ipairs(LayakUI.CurrentMenu.options) do
                if option.type == 'sessionManagement' and option.sessionManagementCallback then
                    option.sessionManagementCallback()
                end
            end
        end
    end
end)

-- Fonction pour ajouter un bouton de gestion des logs
function LayakUI.AddLogManagementButton(menu, label, description, logManagementCallback)
    local option = LayakUI.AddButton(menu, label, description)
    option.type = 'logManagement'
    option.logManagementCallback = logManagementCallback
    return option
end

-- Exemple d'utilisation du bouton de gestion des logs
LayakUI.AddLogManagementButton(mainMenu, 'Gérer Logs', 'Gérez les logs du système', function()
    print('Gestion des logs ouverte!')
    -- Implémentez la logique de gestion des logs ici
end)

-- Mise à jour de la boucle principale pour gérer les boutons de gestion des logs
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        ProcessMenuControls()
        DrawMenu()
        
        if LayakUI.CurrentMenu then
            for i, option in ipairs(LayakUI.CurrentMenu.options) do
                if option.type == 'logManagement' and option.logManagementCallback then
                    option.logManagementCallback()
                end
            end
        end
    end
end)

-- Fonction pour ajouter un bouton de gestion des notifications
function LayakUI.AddNotificationManagementButton(menu, label, description, notificationManagementCallback)
    local option = LayakUI.AddButton(menu, label, description)
    option.type = 'notificationManagement'
    option.notificationManagementCallback = notificationManagementCallback
    return option
end

-- Exemple d'utilisation du bouton de gestion des notifications
LayakUI.AddNotificationManagementButton(mainMenu, 'Gérer Notifications', 'Gérez les notifications du système', function()
    print('Gestion des notifications ouverte!')
    -- Implémentez la logique de gestion des notifications ici
end)

-- Mise à jour de la boucle principale pour gérer les boutons de gestion des notifications
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        ProcessMenuControls()
        DrawMenu()
        
        if LayakUI.CurrentMenu then
            for i, option in ipairs(LayakUI.CurrentMenu.options) do
                if option.type == 'notificationManagement' and option.notificationManagementCallback then
                    option.notificationManagementCallback()
                end
            end
        end
    end
end)
-- Fonction pour ajouter un bouton de gestion des erreurs
function LayakUI.AddErrorManagementButton(menu, label, description, errorManagementCallback)
    local option = LayakUI.AddButton(menu, label, description)
    option.type = 'errorManagement'
    option.errorManagementCallback = errorManagementCallback
    return option
end

-- Exemple d'utilisation du bouton de gestion des erreurs
LayakUI.AddErrorManagementButton(mainMenu, 'Gérer Erreurs', 'Gérez les erreurs du système', function()
    print('Gestion des erreurs ouverte!')
    -- Implémentez la logique de gestion des erreurs ici
end)

-- Mise à jour de la boucle principale pour gérer les boutons de gestion des erreurs
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        ProcessMenuControls()
        DrawMenu()
        
        if LayakUI.CurrentMenu then
            for i, option in ipairs(LayakUI.CurrentMenu.options) do
                if option.type == 'errorManagement' and option.errorManagementCallback then
                    option.errorManagementCallback()
                end
            end
        end
    end
end)

-- Fonction pour ajouter un bouton de gestion des configurations
function LayakUI.AddConfigManagementButton(menu, label, description, configManagementCallback)
    local option = LayakUI.AddButton(menu, label, description)
    option.type = 'configManagement'
    option.configManagementCallback = configManagementCallback
    return option
end

-- Exemple d'utilisation du bouton de gestion des configurations
LayakUI.AddConfigManagementButton(mainMenu, 'Gérer Configurations', 'Gérez les configurations du système', function()
    print('Gestion des configurations ouverte!')
    -- Implémentez la logique de gestion des configurations ici
end)

-- Mise à jour de la boucle principale pour gérer les boutons de gestion des configurations
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        ProcessMenuControls()
        DrawMenu()
        
        if LayakUI.CurrentMenu then
            for i, option in ipairs(LayakUI.CurrentMenu.options) do
                if option.type == 'configManagement' and option.configManagementCallback then
                    option.configManagementCallback()
                end
            end
        end
    end
end)

-- Fonction pour ajouter un bouton de gestion des mises à jour
function LayakUI.AddUpdateManagementButton(menu, label, description, updateManagementCallback)
    local option = LayakUI.AddButton(menu, label, description)
    option.type = 'updateManagement'
    option.updateManagementCallback = updateManagementCallback
    return option
end

-- Exemple d'utilisation du bouton de gestion des mises à jour
LayakUI.AddUpdateManagementButton(mainMenu, 'Gérer Mises à Jour', 'Gérez les mises à jour du système', function()
    print('Gestion des mises à jour ouverte!')
    -- Implémentez la logique de gestion des mises à jour ici
end)

-- Mise à jour de la boucle principale pour gérer les boutons de gestion des mises à jour
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        ProcessMenuControls()
        DrawMenu()
        
        if LayakUI.CurrentMenu then
            for i, option in ipairs(LayakUI.CurrentMenu.options) do
                if option.type == 'updateManagement' and option.updateManagementCallback then
                    option.updateManagementCallback()
                end
            end
        end
    end
end)
-- Fonction pour ajouter un bouton de gestion des sessions
function LayakUI.AddSessionManagementButton(menu, label, description, sessionManagementCallback)
    local option = LayakUI.AddButton(menu, label, description)
    option.type = 'sessionManagement'
    option.sessionManagementCallback = sessionManagementCallback
    return option
end

-- Exemple d'utilisation du bouton de gestion des sessions
LayakUI.AddSessionManagementButton(mainMenu, 'Gérer Sessions', 'Gérez les sessions des utilisateurs', function()
    print('Gestion des sessions ouverte!')
    -- Implémentez la logique de gestion des sessions ici
end)

-- Mise à jour de la boucle principale pour gérer les boutons de gestion des sessions
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        ProcessMenuControls()
        DrawMenu()
        
        if LayakUI.CurrentMenu then
            for i, option in ipairs(LayakUI.CurrentMenu.options) do
                if option.type == 'sessionManagement' and option.sessionManagementCallback then
                    option.sessionManagementCallback()
                end
            end
        end
    end
end)

-- Fonction pour ajouter un bouton de gestion des logs
function LayakUI.AddLogManagementButton(menu, label, description, logManagementCallback)
    local option = LayakUI.AddButton(menu, label, description)
    option.type = 'logManagement'
    option.logManagementCallback = logManagementCallback
    return option
end

-- Exemple d'utilisation du bouton de gestion des logs
LayakUI.AddLogManagementButton(mainMenu, 'Gérer Logs', 'Gérez les logs du système', function()
    print('Gestion des logs ouverte!')
    -- Implémentez la logique de gestion des logs ici
end)

-- Mise à jour de la boucle principale pour gérer les boutons de gestion des logs
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        ProcessMenuControls()
        DrawMenu()
        
        if LayakUI.CurrentMenu then
            for i, option in ipairs(LayakUI.CurrentMenu.options) do
                if option.type == 'logManagement' and option.logManagementCallback then
                    option.logManagementCallback()
                end
            end
        end
    end
end)

-- Fonction pour ajouter un bouton de gestion des notifications
function LayakUI.AddNotificationManagementButton(menu, label, description, notificationManagementCallback)
    local option = LayakUI.AddButton(menu, label, description)
    option.type = 'notificationManagement'
    option.notificationManagementCallback = notificationManagementCallback
    return option
end

-- Exemple d'utilisation du bouton de gestion des notifications
LayakUI.AddNotificationManagementButton(mainMenu, 'Gérer Notifications', 'Gérez les notifications du système', function()
    print('Gestion des notifications ouverte!')
    -- Implémentez la logique de gestion des notifications ici
end)

-- Mise à jour de la boucle principale pour gérer les boutons de gestion des notifications
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        ProcessMenuControls()
        DrawMenu()
        
        if LayakUI.CurrentMenu then
            for i, option in ipairs(LayakUI.CurrentMenu.options) do
                if option.type == 'notificationManagement' and option.notificationManagementCallback then
                    option.notificationManagementCallback()
                end
            end
        end
    end
end)

-- Fonction pour ajouter un bouton de gestion des erreurs
function LayakUI.AddErrorManagementButton(menu, label, description, errorManagementCallback)
    local option = LayakUI.AddButton(menu, label, description)
    option.type = 'errorManagement'
    option.errorManagementCallback = errorManagementCallback
    return option
end

-- Exemple d'utilisation du bouton de gestion des erreurs
LayakUI.AddErrorManagementButton(mainMenu, 'Gérer Erreurs', 'Gérez les erreurs du système', function()
    print('Gestion des erreurs ouverte!')
    -- Implémentez la logique de gestion des erreurs ici
end)

-- Mise à jour de la boucle principale pour gérer les boutons de gestion des erreurs
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        ProcessMenuControls()
        DrawMenu()
        
        if LayakUI.CurrentMenu then
            for i, option in ipairs(LayakUI.CurrentMenu.options) do
                if option.type == 'errorManagement' and option.errorManagementCallback then
                    option.errorManagementCallback()
                end
            end
        end
    end
end)

-- Fonction pour ajouter un bouton de gestion des configurations
function LayakUI.AddConfigManagementButton(menu, label, description, configManagementCallback)
    local option = LayakUI.AddButton(menu, label, description)
    option.type = 'configManagement'
    option.configManagementCallback = configManagementCallback
    return ```lua
end

-- Exemple d'utilisation du bouton de gestion des configurations
LayakUI.AddConfigManagementButton(mainMenu, 'Gérer Configurations', 'Gérez les configurations du système', function()
    print('Gestion des configurations ouverte!')
    -- Implémentez la logique de gestion des configurations ici
end)

-- Mise à jour de la boucle principale pour gérer les boutons de gestion des configurations
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        ProcessMenuControls()
        DrawMenu()
        
        if LayakUI.CurrentMenu then
            for i, option in ipairs(LayakUI.CurrentMenu.options) do
                if option.type == 'configManagement' and option.configManagementCallback then
                    option.configManagementCallback()
                end
            end
        end
    end
end)

-- Fonction pour ajouter un bouton de gestion des mises à jour
function LayakUI.AddUpdateManagementButton(menu, label, description, updateManagementCallback)
    local option = LayakUI.AddButton(menu, label, description)
    option.type = 'updateManagement'
    option.updateManagementCallback = updateManagementCallback
    return option
end

-- Exemple d'utilisation du bouton de gestion des mises à jour
LayakUI.AddUpdateManagementButton(mainMenu, 'Gérer Mises à Jour', 'Gérez les mises à jour du système', function()
    print('Gestion des mises à jour ouverte!')
    -- Implémentez la logique de gestion des mises à jour ici
end)

-- Mise à jour de la boucle principale pour gérer les boutons de gestion des mises à jour
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        ProcessMenuControls()
        DrawMenu()
        
        if LayakUI.CurrentMenu then
            for i, option in ipairs(LayakUI.CurrentMenu.options) do
                if option.type == 'updateManagement' and option.updateManagementCallback then
                    option.updateManagementCallback()
                end
            end
        end
    end
end)

end

-- Exemple d'utilisation du bouton de gestion des mises à jour
LayakUI.AddUpdateManagementButton(mainMenu, 'Gérer Mises à Jour', 'Gérez les mises à jour du système', function()
    print('Gestion des mises à jour ouverte!')
    -- Implémentez la logique de gestion des mises à jour ici
end)

-- Mise à jour de la boucle principale pour gérer les boutons de gestion des mises à jour
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        ProcessMenuControls()
        DrawMenu()
        
        if LayakUI.CurrentMenu then
            for i, option in ipairs(LayakUI.CurrentMenu.options) do
                if option.type == 'updateManagement' and option.updateManagementCallback then
                    option.updateManagementCallback()
                end
            end
        end
    end
end)
end

-- Exemple d'utilisation du bouton de gestion des mises à jour
LayakUI.AddUpdateManagementButton(mainMenu, 'Gérer Mises à Jour', 'Gérez les mises à jour du système', function()
    print('Gestion des mises à jour ouverte!')
    -- Implémentez la logique de gestion des mises à jour ici
end)

-- Mise à jour de la boucle principale pour gérer les boutons de gestion des mises à jour
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        ProcessMenuControls()
        DrawMenu()
        
        if LayakUI.CurrentMenu then
            for i, option in ipairs(LayakUI.CurrentMenu.options) do
                if option.type == 'updateManagement' and option.updateManagementCallback then
                    option.updateManagementCallback()
                end
            end
        end
    end
end)
end

-- Exemple d'utilisation du bouton de gestion des mises à jour
LayakUI.AddUpdateManagementButton(mainMenu, 'Gérer Mises à Jour', 'Gérez les mises à jour du système', function()
    print('Gestion des mises à jour ouverte!')
    -- Implémentez la logique de gestion des mises à jour ici
end)

-- Mise à jour de la boucle principale pour gérer les boutons de gestion des mises à jour
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        ProcessMenuControls()
        DrawMenu()
        
        if LayakUI.CurrentMenu then
            for i, option in ipairs(LayakUI.CurrentMenu.options) do
                if option.type == 'updateManagement' and option.updateManagementCallback then
                    option.updateManagementCallback()
                end
            end
        end
    end
end)
end

-- Exemple d'utilisation du bouton de gestion des mises à jour
LayakUI.AddUpdateManagementButton(mainMenu, 'Gérer Mises à Jour', 'Gérez les mises à jour du système', function()
    print('Gestion des mises à jour ouverte!')
    -- Implémentez la logique de gestion des mises à jour ici
end)

-- Mise à jour de la boucle principale pour gérer les boutons de gestion des mises à jour
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        ProcessMenuControls()
        DrawMenu()
        
        if LayakUI.CurrentMenu then
            for i, option in ipairs(LayakUI.CurrentMenu.options) do
                if option.type == 'updateManagement' and option.updateManagementCallback then
                    option.updateManagementCallback()
                end
            end
        end
    end
end)
end

-- Exemple d'utilisation du bouton de gestion des mises à jour
LayakUI.AddUpdateManagementButton(mainMenu, 'Gérer Mises à Jour', 'Gérez les mises à jour du système', function()
    print('Gestion des mises à jour ouverte!')
    -- Implémentez la logique de gestion des mises à jour ici
end)

-- Mise à jour de la boucle principale pour gérer les boutons de gestion des mises à jour
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        ProcessMenuControls()
        DrawMenu()
        
        if LayakUI.CurrentMenu then
            for i, option in ipairs(LayakUI.CurrentMenu.options) do
                if option.type == 'updateManagement' and option.updateManagementCallback then
                    option.updateManagementCallback()
                end
            end
        end
    end
end)
end

-- Exemple d'utilisation du bouton de gestion des mises à jour
LayakUI.AddUpdateManagementButton(mainMenu, 'Gérer Mises à Jour', 'Gérez les mises à jour du système', function()
    print('Gestion des mises à jour ouverte!')
    -- Implémentez la logique de gestion des mises à jour ici
end)

-- Mise à jour de la boucle principale pour gérer les boutons de gestion des mises à jour
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        ProcessMenuControls()
        DrawMenu()
        
        if LayakUI.CurrentMenu then
            for i, option in ipairs(LayakUI.CurrentMenu.options) do
                if option.type == 'updateManagement' and option.updateManagementCallback then
                    option.updateManagementCallback()
                end
            end
        end
    end
end)
end

-- Exemple d'utilisation du bouton de gestion des mises à jour
LayakUI.AddUpdateManagementButton(mainMenu, 'Gérer Mises à Jour', 'Gérez les mises à jour du système', function()
    print('Gestion des mises à jour ouverte!')
    -- Implémentez la logique de gestion des mises à jour ici
end)

-- Mise à jour de la boucle principale pour gérer les boutons de gestion des mises à jour
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        ProcessMenuControls()
        DrawMenu()
        
        if LayakUI.CurrentMenu then
            for i, option in ipairs(LayakUI.CurrentMenu.options) do
                if option.type == 'updateManagement' and option.updateManagementCallback then
                    option.updateManagementCallback()
                end
            end
        end
    end
end)
end

-- Exemple d'utilisation du bouton de gestion des mises à jour
LayakUI.AddUpdateManagementButton(mainMenu, 'Gérer Mises à Jour', 'Gérez les mises à jour du système', function()
    print('Gestion des mises à jour ouverte!')
    -- Implémentez la logique de gestion des mises à jour ici
end)

-- Mise à jour de la boucle principale pour gérer les boutons de gestion des mises à jour
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        ProcessMenuControls()
        DrawMenu()
        
        if LayakUI.CurrentMenu then
            for i, option in ipairs(LayakUI.CurrentMenu.options) do
                if option.type == 'updateManagement' and option.updateManagementCallback then
                    option.updateManagementCallback()
                end
            end
        end
    end
end)

-- Fonction pour ajouter un système de statistiques
function LayakUI.AddStatsButton(menu, label, description, statsCallback)
    local option = LayakUI.AddButton(menu, label, description)
    option.type = 'stats'
    option.statsCallback = statsCallback
    return option
end

-- Exemple d'utilisation du bouton de statistiques
LayakUI.AddStatsButton(mainMenu, 'Statistiques', 'Voir les statistiques du système', function()
    print('Affichage des statistiques...')
    -- Implémentez la logique d'affichage des statistiques ici
end)

-- Fonction pour ajouter un système de progression
function LayakUI.AddProgressButton(menu, label, description, progressCallback)
    local option = LayakUI.AddButton(menu, label, description)
    option.type = 'progress'
    option.progress = 0
    option.progressCallback = progressCallback
    return option
end

-- Exemple d'utilisation du bouton de progression
LayakUI.AddProgressButton(mainMenu, 'Progression', 'Voir la progression', function(progress)
    print('Progression actuelle: ' .. progress .. '%')
    -- Implémentez la logique de progression ici
end)

-- Fonction pour ajouter un système de badges
function LayakUI.AddBadgeButton(menu, label, description, badgeCallback)
    local option = LayakUI.AddButton(menu, label, description)
    option.type = 'badge'
    option.badges = {}
    option.badgeCallback = badgeCallback
    return option
end

-- Exemple d'utilisation du bouton de badges
LayakUI.AddBadgeButton(mainMenu, 'Badges', 'Voir vos badges', function()
    print('Affichage des badges...')
    -- Implémentez la logique d'affichage des badges ici
end)

-- Mise à jour de la boucle principale pour gérer les nouveaux types de boutons
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        ProcessMenuControls()
        DrawMenu()
        
        if LayakUI.CurrentMenu then
            for i, option in ipairs(LayakUI.CurrentMenu.options) do
                -- Gestion des statistiques
                if option.type == 'stats' and option.statsCallback then
                    option.statsCallback()
                end
                
                -- Gestion de la progression
                if option.type == 'progress' and option.progressCallback then
                    option.progressCallback(option.progress)
                    -- Mise à jour automatique de la progression
                    option.progress = math.min(100, option.progress + 1)
                end
                
                -- Gestion des badges
                if option.type == 'badge' and option.badgeCallback then
                    option.badgeCallback()
                end
            end
        end
    end
end)

-- Fonction pour ajouter un système de récompenses
function LayakUI.AddRewardButton(menu, label, description, rewardCallback)
    local option = LayakUI.AddButton(menu, label, description)
    option.type = 'reward'
    option.rewards = {}
    option.rewardCallback = rewardCallback
    return option
end

-- Exemple d'utilisation du bouton de récompenses
LayakUI.AddRewardButton(mainMenu, 'Récompenses', 'Voir vos récompenses', function()
    print('Affichage des récompenses...')
    -- Implémentez la logique d'affichage des récompenses ici
end)

-- Fonction pour ajouter un système de classement
function LayakUI.AddLeaderboardButton(menu, label, description, leaderboardCallback)
    local option = LayakUI.AddButton(menu, label, description)
    option.type = 'leaderboard'
    option.leaderboard = {}
    option.leaderboardCallback = leaderboardCallback
    return option
end

-- Exemple d'utilisation du bouton de classement
LayakUI.AddLeaderboardButton(mainMenu, 'Classement', 'Voir le classement', function()
    print('Affichage du classement...')
    -- Implémentez la logique d'affichage du classement ici
end)

-- Mise à jour de la boucle principale pour gérer les nouveaux types de boutons
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        ProcessMenuControls()
        DrawMenu()
        
        if LayakUI.CurrentMenu then
            for i, option in ipairs(LayakUI.CurrentMenu.options) do
                -- Gestion des récompenses
                if option.type == 'reward' and option.rewardCallback then
                    option.rewardCallback()
                end
                
                -- Gestion du classement
                if option.type == 'leaderboard' and option.leaderboardCallback then
                    option.leaderboardCallback()
                end
            end
        end
    end
end)

-- Système de notifications et d'événements
function LayakUI.AddNotificationSystem(menu, label, description)
    local notifications = {
        queue = {},
        active = false,
        maxNotifications = 5,
        displayTime = 3000, -- 3 secondes
    }

    -- Fonction pour ajouter une notification
    function notifications:AddNotification(title, message, type)
        if #self.queue >= self.maxNotifications then
            table.remove(self.queue, 1)
        end
        
        table.insert(self.queue, {
            title = title,
            message = message,
            type = type or "info", -- info, success, warning, error
            timestamp = GetGameTimer(),
            alpha = 255
        })
    end

    -- Fonction pour dessiner les notifications
    function notifications:Draw()
        local currentTime = GetGameTimer()
        local yOffset = 0.1

        for i = #self.queue, 1, -1 do
            local notif = self.queue[i]
            local elapsedTime = currentTime - notif.timestamp
            
            if elapsedTime > self.displayTime then
                notif.alpha = math.max(0, notif.alpha - 5)
                if notif.alpha == 0 then
                    table.remove(self.queue, i)
                end
            end

            -- Dessiner le fond de la notification
            local backgroundColor = {r = 0, g = 0, b = 0, a = notif.alpha * 0.8}
            if notif.type == "success" then
                backgroundColor = {r = 0, g = 155, b = 0, a = notif.alpha * 0.8}
            elseif notif.type == "warning" then
                backgroundColor = {r = 155, g = 155, b = 0, a = notif.alpha * 0.8}
            elseif notif.type == "error" then
                backgroundColor = {r = 155, g = 0, b = 0, a = notif.alpha * 0.8}
            end

            DrawRect(0.85, yOffset, 0.2, 0.05, 
                backgroundColor.r, 
                backgroundColor.g, 
                backgroundColor.b, 
                backgroundColor.a
            )

            -- Dessiner le texte
            DrawText2D(notif.title, 0.76, yOffset - 0.015, 0.3, 4, true, 255, 255, 255, notif.alpha)
            DrawText2D(notif.message, 0.76, yOffset + 0.005, 0.25, 4, false, 255, 255, 255, notif.alpha)

            yOffset = yOffset + 0.06
        end
    end

    -- Ajouter le bouton de notification au menu
    local option = LayakUI.AddButton(menu, label, description)
    option.type = 'notification'
    option.notifications = notifications
    
    return option
end

-- Système d'événements personnalisés
LayakUI.Events = {
    listeners = {},
    RegisterEvent = function(eventName, callback)
        if not LayakUI.Events.listeners[eventName] then
            LayakUI.Events.listeners[eventName] = {}
        end
        table.insert(LayakUI.Events.listeners[eventName], callback)
    end,
    
    TriggerEvent = function(eventName, ...)
        if LayakUI.Events.listeners[eventName] then
            for _, callback in ipairs(LayakUI.Events.listeners[eventName]) do
                callback(...)
            end
        end
    end
}

-- Exemple d'utilisation du système de notifications
local notifSystem = LayakUI.AddNotificationSystem(mainMenu, 'Notifications', 'Gérer les notifications')

-- Exemples d'utilisation
Citizen.CreateThread(function()
    -- Enregistrer un événement
    LayakUI.Events.RegisterEvent('onPlayerAction', function(action)
        notifSystem.notifications:AddNotification('Action Joueur', 'Action: ' .. action, 'info')
    end)

    -- Enregistrer un événement de succès
    LayakUI.Events.RegisterEvent('onMissionComplete', function(missionName)
        notifSystem.notifications:AddNotification('Mission Accomplie', 'Mission ' .. missionName .. ' terminée!', 'success')
    end)

    -- Enregistrer un événement d'erreur
    LayakUI.Events.RegisterEvent('onError', function(errorMsg)
        notifSystem.notifications:AddNotification('Erreur', errorMsg, 'error')
    end)
end)

-- Mise à jour de la boucle principale pour inclure le système de notifications
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        ProcessMenuControls()
        DrawMenu()
        
        if LayakUI.CurrentMenu then
            for i, option in ipairs(LayakUI.CurrentMenu.options) do
                if option.type == 'notification' then
                    option.notifications:Draw()
                end
            end
        end

        -- Exemple de déclenchement d'événements
        if IsControlJustPressed(0, 38) then -- Touche E
            LayakUI.Events.TriggerEvent('onPlayerAction', 'Touche E pressée')
        end
    end
end)

-- Fonction utilitaire pour tester les notifications
function TestNotifications()
    notifSystem.notifications:AddNotification('Test Info', 'Ceci est une notification info', 'info')
    Citizen.Wait(1000)
    notifSystem.notifications:AddNotification('Test Success', 'Ceci est une notification succès', 'success')
    Citizen.Wait(1000)
    notifSystem.notifications:AddNotification('Test Warning', 'Ceci est une notification warning', 'warning')
    Citizen.Wait(1000)
    notifSystem.notifications:AddNotification('Test Error', 'Ceci est une notification erreur', 'error')
end

-- Système de thèmes et d'animations avancées
LayakUI.AddAdvancedFeatures = function()
    local features = {
        particles = {},
        backgrounds = {},
        soundEnabled = true,
        visualEffects = true
    }

    -- Système de particules
    function features.CreateParticle(x, y)
        table.insert(features.particles, {
            x = x,
            y = y,
            size = math.random(2, 5) / 10,
            speed = math.random(5, 15) / 100,
            alpha = 255,
            color = {r = 255, g = 255, b = 255}
        })
    end

    -- Gestionnaire d'effets sonores
    function features.PlayMenuSound(type)
        if features.soundEnabled then
            if type == "hover" then
                PlaySoundFrontend(-1, "NAV_UP_DOWN", "HUD_FRONTEND_DEFAULT_SOUNDSET", true)
            elseif type == "select" then
                PlaySoundFrontend(-1, "SELECT", "HUD_FRONTEND_DEFAULT_SOUNDSET", true)
            elseif type == "back" then
                PlaySoundFrontend(-1, "BACK", "HUD_FRONTEND_DEFAULT_SOUNDSET", true)
            end
        end
    end

    -- Effets visuels avancés
    function features.DrawMenuBackground()
        if features.visualEffects then
            -- Effet de flou dynamique
            DrawRect(0.5, 0.5, 1.0, 1.0, 0, 0, 0, 150)
            
            -- Animation de particules
            for i = #features.particles, 1, -1 do
                local particle = features.particles[i]
                particle.y = particle.y - particle.speed
                particle.alpha = particle.alpha - 2
                
                if particle.alpha <= 0 then
                    table.remove(features.particles, i)
                else
                    DrawRect(particle.x, particle.y, particle.size, particle.size, 
                        particle.color.r, particle.color.g, particle.color.b, particle.alpha)
                end
            end
        end
    end

    -- Effet de transition
    function features.DrawTransition(progress)
        if features.visualEffects then
            local height = 0.1 * progress
            DrawRect(0.5, 0.5, 1.0, height, 0, 0, 0, 200)
        end
    end

    -- Hook pour les événements du menu
    Citizen.CreateThread(function()
        while true do
            Citizen.Wait(0)
            if LayakUI.CurrentMenu then
                features.DrawMenuBackground()
                
                -- Génération aléatoire de particules
                if math.random() < 0.1 then
                    features.CreateParticle(math.random(), math.random())
                end
            end
        end
    end)

    -- Ajout des contrôles sonores
    local originalProcessControls = ProcessMenuControls
    ProcessMenuControls = function()
        local menuChanged = false
        local oldMenu = LayakUI.CurrentMenu
        
        originalProcessControls()
        
        if oldMenu ~= LayakUI.CurrentMenu then
            features.PlayMenuSound("select")
            menuChanged = true
        end
        
        if menuChanged then
            features.DrawTransition(0.5)
        end
    end

    return features
end

-- Initialisation des fonctionnalités avancées
local advancedFeatures = LayakUI.AddAdvancedFeatures()

-- Système de notifications et barres de progression
local function InitializeExtendedFeatures()
    local extended = {
        notifications = {
            active = {},
            queue = {},
            maxActive = 3,
            types = {
                success = {r = 75, g = 181, b = 67},
                error = {r = 181, g = 67, b = 67},
                info = {r = 67, g = 137, b = 181},
                warning = {r = 181, g = 167, b = 67}
            }
        },
        progress = {
            active = {},
            maxActive = 5
        }
    }

    -- Gestionnaire de notifications
    function extended.ShowNotification(message, type, duration)
        table.insert(extended.notifications.queue, {
            message = message,
            type = type or 'info',
            duration = duration or 3000,
            opacity = 0,
            startTime = GetGameTimer(),
            state = 'entering'
        })
    end

    -- Barre de progression
    function extended.CreateProgressBar(label, duration, onComplete)
        local id = #extended.progress.active + 1
        extended.progress.active[id] = {
            label = label,
            duration = duration,
            startTime = GetGameTimer(),
            progress = 0,
            onComplete = onComplete
        }
        return id
    end

    -- Rendu des éléments
    Citizen.CreateThread(function()
        while true do
            Citizen.Wait(0)
            -- Rendu des notifications
            local y = 0.8
            for i, notif in ipairs(extended.notifications.active) do
                local color = extended.notifications.types[notif.type]
                DrawRect(0.5, y, 0.2, 0.05, color.r, color.g, color.b, notif.opacity)
                SetTextScale(0.3, 0.3)
                SetTextColour(255, 255, 255, notif.opacity)
                SetTextCentre(true)
                SetTextEntry("STRING")
                AddTextComponentString(notif.message)
                DrawText(0.5, y - 0.0125)
                y = y - 0.06
            end

            -- Rendu des barres de progression
            y = 0.2
            for id, bar in pairs(extended.progress.active) do
                local elapsed = GetGameTimer() - bar.startTime
                bar.progress = math.min(elapsed / bar.duration, 1.0)
                
                DrawRect(0.5, y, 0.2, 0.03, 0, 0, 0, 150)
                DrawRect(0.5 - (0.1 * (1 - bar.progress)), y, 0.2 * bar.progress, 0.03, 67, 137, 181, 200)
                
                SetTextScale(0.25, 0.25)
                SetTextColour(255, 255, 255, 255)
                SetTextCentre(true)
                SetTextEntry("STRING")
                AddTextComponentString(bar.label)
                DrawText(0.5, y - 0.015)
                
                if bar.progress >= 1.0 then
                    if bar.onComplete then bar.onComplete() end
                    extended.progress.active[id] = nil
                end
                y = y + 0.04
            end
        end
    end)

    return extended
end

-- Initialisation des fonctionnalités étendues
local extendedFeatures = InitializeExtendedFeatures()