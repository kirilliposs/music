/*-
 * Copyright (c) 2011       Scott Ringwelski <sgringwe@mtu.edu>
 *
 * Originally Written by Scott Ringwelski for BeatBox Music Player
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

public class BeatBox.CoverArtImage : Image {
	LibraryManager lm;
	LibraryWindow lw;
	
	public Gdk.Pixbuf defaultImage;
	
	public CoverArtImage(LibraryManager lmm, LibraryWindow lww) {
		lm = lmm;
		lw = lww;
		
		drag_dest_set(this, DestDefaults.ALL, {}, Gdk.DragAction.MOVE);
		Gtk.drag_dest_add_uri_targets(this);
		this.drag_data_received.connect(dragReceived);
	}
	
	private bool is_valid_image_type(string type) {
		var typeDown = type.down();
		
		return (typeDown.has_suffix(".jpg") || typeDown.has_suffix(".jpeg") ||
				typeDown.has_suffix(".png"));
	}
	
	public virtual void dragReceived(Gdk.DragContext context, int x, int y, Gtk.SelectionData data, uint info, uint timestamp) {
		bool success = false;
		
		foreach(string singleUri in data.get_uris()) {
			
			if(is_valid_image_type(singleUri)) {
				var original = File.new_for_uri(singleUri);
				var playingPath = File.new_for_path(lm.media_info.media.file); // used to get dest
				var dest = File.new_for_path(Path.build_path("/", playingPath.get_parent().get_path(), "Album.jpg"));
				var destTemp = File.new_for_path(Path.build_path("/", playingPath.get_parent().get_path(), "AlbumTemporaryPathToEnsureNoProtection.jpg"));
				
				bool copySuccess = false;
				
				try {
					success = original.copy(destTemp, FileCopyFlags.NONE, null, null);
				}
				catch(Error err) {
					stdout.printf("Couldn't copy file over\n");
				}
				
				if(copySuccess) {
					
					// test successful, no block on copy
					if(dest.query_exists()) {
						try {
							dest.delete();
						}
						catch(Error err) {
							stdout.printf("Could not delete previous file\n");
						}
					}
					
					try {
						destTemp.move(dest, FileCopyFlags.NONE, null, null);
					}
					catch(Error err) {
						stdout.printf("Could not move to destination\n");
					}
					
					Gee.LinkedList<Media> updated_medias = new Gee.LinkedList<Media>();
					foreach(int id in lm.media_ids()) {
						if(lm.media_from_id(id).artist == lm.media_info.media.artist && lm.media_from_id(id).album == lm.media_info.media.album)
							lm.media_from_id(id).setAlbumArtPath(dest.get_path());
							updated_medias.add(lm.media_from_id(id));
					}
					
					// wait for everything to finish up and then update the medias
					Timeout.add(2000, () => {
						
						try {
							Thread.create<void*>(lm.fetch_thread_function, false);
						}
						catch(GLib.ThreadError err) {
							stdout.printf("Could not create thread to load media pixbuf's: %s \n", err.message);
						}
						
						lm.update_medias(updated_medias, false, false);
						
						// for sound menu (dbus doesn't like linked lists)
						if(updated_medias.contains(lm.media_info.media))
							lm.update_media(lm.media_info.media, false, false);
						
						return false;
					});
					success = true;
				}
			}
			
			lw.updateCurrentMedia();
			Gtk.drag_finish (context, success, false, timestamp);
			return;
		}
    }
	
	
}
