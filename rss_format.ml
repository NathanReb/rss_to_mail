open Xml_utils
open Feed

let parse rss_elem =
	let dc_ns = namespace "http://purl.org/dc/elements/1.1/" in
	let parse_item item =
		let child_text_opt tag =
			try Some (text (child tag item))
			with _ -> None
		in
		let date =
			Int64.of_float @@
			Js.date##parse (node (child "pubDate" item))##getText
		and categories =
			let parse_category cat =
				{ term = None; label = Some (text cat) } in
			List.map parse_category (children "category" item)
		and authors =
			List.map text (children ~ns:dc_ns "creator" item)
		in
		{	title = text (child "title" item);
			link = child_text_opt "link";
			id = child_text_opt "guid";
			summary = None;
			content = child_text_opt "description";
			authors; date; categories }
	in
	let channel = child "channel" rss_elem in
	let entries =
		Array.of_list (children "item" channel)
		|> Array.map parse_item
	in
	{	feed_title = text (child "title" channel);
		feed_link = (try Some (text (child "link" channel)) with _ -> None);
		entries }
