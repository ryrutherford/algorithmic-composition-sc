
//loads all the soundfiles from the buffers
//the buffers contain all the percussive elements
(
b = Dictionary.new;
PathName("C:/Users/Ry Rutherford/Documents/Supercollider Projects/algorithmic-composition/buffers").entries.do{
	arg subfolder;
	b.add(
		subfolder.folderName.asSymbol ->
		Array.fill(
			subfolder.entries.size,
			{
				arg i;
				Buffer.read(s, subfolder.entries[i].fullPath);
			}
		)
	);
};
)

b[\kicks][3].play;