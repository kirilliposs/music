/*-
 * Copyright (c) 2011-2012       Scott Ringwelski <sgringwe@mtu.edu>
 *
 * Originaly Written by Scott Ringwelski for BeatBox Music Player
 * BeatBox Music Player: http://www.launchpad.net/beat-box
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Library General Public
 * License as published by the Free Software Foundation; either
 * version 2 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Library General Public License for more details.
 *
 * You should have received a copy of the GNU Library General Public
 * License along with this library; if not, write to the
 * Free Software Foundation, Inc., 59 Temple Place - Suite 330,
 * Boston, MA 02111-1307, USA.
 */

using Gtk;

#if USE_GRANITE_DECORATED_WINDOW
public class Noise.PlaylistNameWindow : Granite.Widgets.LightWindow {
#else
public class Noise.PlaylistNameWindow : Window {
#endif

    public Playlist _original;
    LibraryWindow lw;
    
    Gtk.Box content;
    Gtk.Label infobar_label;

    public Entry _name {get; private set;}
    public Button _save {get; private set;}
    public Button _cancel {get; private set;}

    public signal void playlist_saved(Playlist p);
    
    public PlaylistNameWindow(LibraryWindow lw, Playlist original) {
        this.lw = lw;
        
        this.title = _("Playlist Editor");
        
        this.window_position = WindowPosition.CENTER;
        this.type_hint = Gdk.WindowTypeHint.DIALOG;
        this.set_modal(true);
        this.set_transient_for(lw);
        this.destroy_with_parent = true;

        set_size_request (350, -1);
        resizable = false;
        
        _original = original;
        
        content = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
        
        /* start out by creating all category labels */
        Label nameLabel = new Label(_("Name of Playlist"));
        _name = new Entry();
        _save = new Button.from_stock (Gtk.Stock.SAVE);
        _cancel = new Button.from_stock (Gtk.Stock.CANCEL);


        /* set up controls */
        nameLabel.xalign = 0.0f;
        nameLabel.set_markup("<b>%s</b>".printf (String.escape (_("Name of Playlist"))));
        
        _name.text = original.name;
        
        /* Infobar stuff*/
        infobar_label = new Label("");
        
        infobar_label.set_justify(Justification.LEFT);
        infobar_label.xalign = 0.0f;
        infobar_label.set_single_line_mode(true);
        infobar_label.ellipsize = Pango.EllipsizeMode.END;

        /* add controls to form */
        var bottomButtons = new Gtk.ButtonBox (Gtk.Orientation.HORIZONTAL);
        bottomButtons.set_spacing (6);
        bottomButtons.set_layout (Gtk.ButtonBoxStyle.END);
        bottomButtons.pack_end (_cancel, false, false, 0);
        bottomButtons.pack_end (_save, false, false, 0);

        infobar_label.set_no_show_all (true);
        
        content.pack_start (nameLabel, false, false, 0);
        _name.margin_top = 6;
        content.pack_start (_name, false, false, 0);
        infobar_label.margin_top = 6;
        content.pack_start (infobar_label, false, false, 0);
        bottomButtons.margin_top = 12;
        content.pack_start (bottomButtons, false, false, 0);

        content.margin = 12;

        add(content);

        // Validate initial state
        nameChanged ();

        show_all();

        _save.clicked.connect(saveClicked);
        _cancel.clicked.connect (cancel_clicked);
        _name.activate.connect(nameActivate);
        _name.changed.connect(nameChanged);
    }

    void cancel_clicked () {
        destroy ();
    }

    void saveClicked() {
        if (_save.get_sensitive() == true) {
            _original.name = _name.text.strip ();
            playlist_saved (_original);
            this.destroy();
        }
    }
    
    void nameActivate() {
        saveClicked();
    }
    
    void nameChanged() {
        if (String.is_white_space (_name.get_text())) {
            _save.set_sensitive(false);
            infobar_label.hide ();
            return;
        }
        else {
            foreach (var p in lw.library_manager.playlists ()) {
                var fixed_name = _name.get_text ().strip ();
                if((_original == null || _original.rowid != p.rowid) && fixed_name == p.name) {
                    _save.set_sensitive(false);
                    infobar_label.set_no_show_all (false);
                    infobar_label.set_markup (_("The name %s is already in use").printf ("<b>" + String.escape (fixed_name) + "</b>"));
                    infobar_label.show_all ();
                    return;
                }
            }
        }

        infobar_label.hide ();        
        _save.set_sensitive(true);
    }
}
