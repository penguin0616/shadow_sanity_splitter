name = "Shadow Sanity Splitter"
description = "Splits the sanity from fighting shadow creatures among the participants.\nCan be configured."
author = "penguin0616"
version = "1.0.1"
forumthread = ""
icon_atlas = "modicon.xml"
icon = "modicon.tex"
dst_compatible = true
server_only_mod = true
client_only_mod = false
all_clients_require_mod = false

api_version_dst = 10

configuration_options = {
	{
		name = "split_type",
		label = "Split Mode",
		hover = "How the sanity reward is distributed.",
		options = {
			{data = 0, description = "Damage dealt", hover = "Sanity is distributed based on how much damage each person dealt."},
			{data = 1, description = "Participation", hover = "An equal amount of sanity is distributed to anyone who hit the shadow."},
			{data = 2, description = "Spawner", hover = "Sanity goes to the shadow spawner. Not recommended."},
		}, 
		default = 0
	}
}