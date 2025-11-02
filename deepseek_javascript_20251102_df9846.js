// ANTES (errado):
NOTES.push({ midi: i, name: note: noteName, isBlack: isBlack, octave: Tone.Midi(i).toOctave() });

// DEPOIS (correto):
NOTES.push({ 
    midi: i, 
    name: noteName, 
    isBlack: isBlack, 
    octave: Tone.Midi(i).toOctave() 
});