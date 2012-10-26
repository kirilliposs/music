// -*- Mode: vala; indent-tabs-mode: nil; tab-width: 4 -*-
/*-
 * Copyright (c) 2012 Noise Developers (http://launchpad.net/noise)
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this library; if not, write to the
 * Free Software Foundation, Inc., 59 Temple Place - Suite 330,
 * Boston, MA 02111-1307, USA.
 *
 * Authored by: Victor Eduardo <victoreduardm@gmail.com>
 */

public class Noise.QueueViewWrapper : ViewWrapper {

    public QueueViewWrapper (LibraryWindow lw) {
        base (lw, Hint.QUEUE);
        build_async.begin ();
    }

    private async void build_async () {
        list_view = new ListView (this, lw.library_manager.queue_setup);
        embedded_alert = new Granite.Widgets.EmbeddedAlert ();

        // Refresh view layout
        pack_views ();

        yield set_media_async (App.player.queue ());
        connect_data_signals ();
    }

    private void connect_data_signals () {
         App.player.queue_cleared.connect (on_queue_cleared);
         App.player.media_queued.connect (on_media_queued);
         App.player.media_unqueued.connect (on_media_unqueued);

         lm.media_removed.connect (on_library_media_removed);
    }

    private async void on_queue_cleared () {
        yield set_media_async (new Gee.LinkedList<Media> ());
    }

    private async void on_media_queued (Gee.Collection<Media> queued) {
        yield add_media_async (queued);
    }

    private async void on_media_unqueued (Gee.Collection<Media> unqueued) {
        yield remove_media_async (unqueued);
    }

    private async void on_library_media_removed (Gee.Collection<int> ids) {
        yield remove_media_async (lm.media_from_ids (ids));
    }

    protected override void set_no_media_alert () {
        embedded_alert.set_alert (_("No songs in Queue"), _("To add songs to the queue, use the <b>secondary click</b> on an item and choose <b>Queue</b>. When a song finishes, the queued songs will be played first before the next song in the currently playing list."), null, true, Gtk.MessageType.INFO);
    }
}

