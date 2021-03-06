open Feed
open Tyxml

let opt_link text = function
  | Some uri	->
    [%html "<a href=" (Uri.to_string uri) ">"[ Html.txt text ]"</a>"]
  | None		-> Html.txt text

let rec list_interleave elt = function
  | [ _ ] as last	-> last
  | hd :: tl		-> hd :: elt :: list_interleave elt tl
  | []			-> []

let gen_entry ~sender ?label feed entry =
  let entry_title =
    match entry.title, entry.link with
    | Some t, link				-> opt_link t link
    | None, (Some l as link)	-> opt_link (Uri.to_string l) link
    | None, None				-> [%html "New entry"]

  and header =
    let feed_icon = match feed.feed_icon with
      | Some url	-> [ [%html "<img width=\"16\" height=\"16\"
				src=" (Uri.to_string url) "
				alt=" sender "
				style=\"display: inline !important;
					height: 1em !important;
					margin: 0 0 -0.1em 0 !important\" />"];
                      Html.txt " " ]
      | None		-> []

    and feed_title = [ opt_link sender feed.feed_link ]

    and categories =
      match List.filter_map (function
          | { label = Some _ as c; _ }
          | { term = Some _ as c; _ } -> c
          | _ -> None
        ) entry.categories with
      | []	-> []
      | lst	-> [ Html.txt (" (" ^ String.concat ", " lst ^ ")") ]

    and date =
      match entry.date with
      | Some date		-> [ Html.txt (" on " ^ date) ]
      | None			-> []

    and authors =
      let author a = opt_link a.author_name a.author_link in
      match List.map author entry.authors with
      | []		-> []
      | authors	->
        Html.txt " by " :: list_interleave (Html.txt ", ") authors

    and label =
      match label with
      | Some l	-> [ Html.txt (" with label " ^ l) ]
      | None		-> []
    in

    [%html feed_icon feed_title categories date authors label ]

  and thumbnail =
    match entry.thumbnail with
    | Some src	-> [ [%html "<td>
				<img class=\"thumbnail\" alt=\"thumbnail\"
					width=\"60\" height=\"60\"
					src=" (Uri.to_string src) " />
			</td>"] ]
    | None		-> []

  and attachments =
    let attachment i t =
      let info =
        match Option.map Utils.size t.attach_size, t.attach_type with
        | Some i, None | None, Some i -> [ Html.txt (" (" ^ i ^ ")") ]
        | Some s, Some t -> [ Html.txt (" (" ^ s ^ ", " ^ t ^ ")") ]
        | None, None -> []
      and link =
        [ opt_link (Uri.path t.attach_url) (Some t.attach_url) ]
      and index = [ Html.txt (string_of_int (i + 1)) ]
      in
      [%html "<tr><td>Attachment " index ": " link "" info "</td></tr>"]
    in
    match entry.attachments with
    | []		-> []
    | attchmts	-> [ Html.table (List.mapi attachment attchmts) ]

  and content =
    let w cont = [ [%html "<div class=\"content\">"[ cont ]"</div>"] ] in
    match Option.or_ ~else_:entry.summary entry.content with
    | Some (Text txt)	-> w (Html.txt txt)
    | Some (Html node)	-> w node
    | None				-> []
  in

  let header_table =
    [ Html.table [
          Html.tr (
            thumbnail
            @ [ [%html "<td>
					<h1 class=\"entry_title\">"[ entry_title ]"</h1>
					<p class=\"entry_header\">" header "</p>
				</td>"] ]
          )
        ] ]
  in

  [%html header_table attachments content]

let gen_summary sum =
  [%html "<span style=\"display:none;font-size:1px;color:#333333;
		line-height:1px;max-height:0px;max-width:0px;opacity:0;
		overflow:hidden;\">"[ Html.txt sum ]"</span>"]

let gen_mail ~sender ?hidden_summary entries =
  let entries = match entries with
    | [ e ]		-> e
    | entries	-> List.map (fun e -> [%html "<div>" e "</div>"]) entries
  in
  [%html "
<html lang=\"en\">
	<head>
		<style>
a { text-decoration: none; }
.entry_title { margin: 0; }
.entry_title a { border-bottom: 1px dashed black; }
.entry_header { margin-top: 0; }
.content { margin: 20px 0 25px 10px; max-width: 600px; }
.thumbnail { display: block; margin: 0 5px 5px 0; width: 60px; height: 60px; }
		</style>
		<title>" (Html.txt sender) "</title>
	</head>
	<body>"
      (Option.to_list hidden_summary)
      entries
      "</body>
</html>
"]
