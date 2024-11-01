import St from 'gi://St';
import GLib from 'gi://GLib';
import Clutter from 'gi://Clutter';
import { Extension } from 'resource:///org/gnome/shell/extensions/extension.js';
import * as Main from 'resource:///org/gnome/shell/ui/main.js';
import * as PanelMenu from 'resource:///org/gnome/shell/ui/panelMenu.js';
import * as PopupMenu from 'resource:///org/gnome/shell/ui/popupMenu.js';

export default class extends Extension {
    enable() {
        this._panelMenuButton = new PanelMenu.Button(0, this.metadata.name, false);

        this._panelMenuButton.add_child(
            new St.Icon({
                icon_name: 'applets-screenshooter-symbolic',
                style_class: 'system-status-icon',
            })
        );

        Main.panel.addToStatusArea(this.uuid, this._panelMenuButton);

        this._panelMenuButton.connect('button-release-event', this._onButtonRelease.bind(this));

        this._addMenuItems();
    }

    _onButtonRelease() {
        this._panelMenuButton.menu.open();
    }

    _addMenuItems() {
        const menuItems = [
            { label: "Take Area Screenshot", command: 'screenedit -a' },
            { label: "Take Current Window Screenshot", command: 'screenedit -w' },
            { label: "Take Full Screenshot", command: 'screenedit -f' },
            { label: "Launch Interactive", command: 'screenedit -i' }
        ];

        menuItems.forEach(({ label, command }) => {
            const menuItem = new PopupMenu.PopupMenuItem(label);
            menuItem.connect('activate', () => {
                try {
                    GLib.spawn_command_line_async(command);
                } catch (e) {
                    log(`Failed to execute command "${command}": ${e}`);
                }
            });
            this._panelMenuButton.menu.addMenuItem(menuItem);
        });
    }

    disable() {
        if (this._panelMenuButton) {
            this._panelMenuButton.disconnect(this._onButtonRelease.bind(this));
            this._panelMenuButton.destroy();
            this._panelMenuButton = null;
        }
    }
}
