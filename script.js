/**
 * script.js
 * Lógica de Interface (UI), Geração de Teclas e Mapeamento do Teclado do PC.
 * Integração com o AudioEngine.
 */

// --- VARIÁVEIS DE CONFIGURAÇÃO DO TECLADO ---
const START_MIDI_NOTE = 30; // F1 
const END_MIDI_NOTE = 96;   // C7 (67 teclas)

// Mapeamento PC -> MIDI (5.5 Oitavas)
const PC_KEY_MAP = {
    // F1 - E2: Z/S/X/D/C/F/V/G/B/H/N/J...
    'z': 30, 's': 31, 'x': 32, 'd': 33, 'c': 34, 'f': 35, 'v': 36, 'g': 37, 'b': 38, 'h': 39, 'n': 40, 'j': 41,
    // F2 - E3: Y/7/U/8/I/9/O/0/P... (Fileira superior)
    'y': 42, '7': 43, 'u': 44, '8': 45, 'i': 46, '9': 47, 'o': 48, '0': 49, 'p': 50, '-': 51, '[': 52, ']': 53,
    // F3 - E4: Q/2/W/3/E/4/R/5/T... (Fileira Q)
    'q': 54, '2': 55, 'w': 56, '3': 57, 'e': 58, '4': 59, 'r': 60, '5': 61, 't': 62, '6': 63, 'y': 64, '7': 65,
    // C4 a C7 (Oitavas Superiores)
    'a': 69, 'k': 71, 'l': 72, ';': 74, "'": 76,
    
}; 

const SHARPS = [1, 3, 6, 8, 10]; // Intervalos de notas que são pretas

// --- ESTADO DO MOTOR ---
const CURRENT_PRESET = "DX7_E_PIANO_1"; 
const pressedKeys = new Map(); // Rastreia as teclas do PC pressionadas

// 1. Geração Dinâmica das 67 Teclas (Com correção de posicionamento)
function generateKeys() {
    const keyboard = document.getElementById('virtual-keyboard');
    const NOTE_NAMES = ['C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B'];
    const WHITE_KEY_COUNT = 39; 
    // Correção: Usar o valor CSS exato para o cálculo de posição
    const WHITE_KEY_WIDTH_PERCENT = 2.5641; 
    const BLACK_KEY_OFFSET_PERCENT = 1.7; 

    let whiteKeyIndex = 0;

    for (let i = START_MIDI_NOTE; i <= END_MIDI_NOTE; i++) {
        const octave = Math.floor(i / 12) - 1;
        const noteIndex = i % 12;

        const isSharp = SHARPS.includes(noteIndex);
        const key = document.createElement('div');
        key.classList.add('key');
        key.setAttribute('data-midi', i);

        if (isSharp) {
            key.classList.add('black-key');
            
            // Posição: A tecla preta flutua sobre as brancas. 
            // Calcula a posição do centro da tecla branca anterior menos um offset
            const position = (whiteKeyIndex * WHITE_KEY_WIDTH_PERCENT) - BLACK_KEY_OFFSET_PERCENT;
            key.style.left = `${position}%`;

        } else {
            key.classList.add('white-key');
            // Posicionamento horizontal exato das teclas brancas
            key.style.left = `${whiteKeyIndex * WHITE_KEY_WIDTH_PERCENT}%`;
            whiteKeyIndex++;
        }
        
        // Mapeamento de Cifra (Label)
        const label = document.createElement('span');
        label.classList.add('cifra-label');
        label.innerText = NOTE_NAMES[noteIndex] + octave;
        key.appendChild(label);
        
        keyboard.appendChild(key);
    }
    document.querySelectorAll('.cifra-label').forEach(label => label.style.display = 'none');
}

// 2. Mapeamento do Teclado do PC (Eventos)
document.addEventListener('keydown', (event) => {
    // CORREÇÃO CRÍTICA DE ÁUDIO: Ativa o AudioContext no primeiro Keydown
    if (audioEngine && audioEngine.context.state === 'suspended') {
        audioEngine.context.resume();
        console.log("AudioContext resumed on user interaction.");
    }
    
    const pcKey = event.key.toLowerCase();
    const midiNote = PC_KEY_MAP[pcKey];

    if (midiNote && !pressedKeys.has(pcKey)) {
        pressedKeys.set(pcKey, midiNote);
        event.preventDefault(); 
        
        // Aciona o motor de som
        audioEngine.playNote(midiNote, CURRENT_PRESET); 
        
        // Ativa a tecla visualmente
        const keyElement = document.querySelector(`[data-midi="${midiNote}"]`);
        if (keyElement) keyElement.classList.add('active');
    }
});

document.addEventListener('keyup', (event) => {
    const pcKey = event.key.toLowerCase();

    if (pressedKeys.has(pcKey)) {
        const midiNote = pressedKeys.get(pcKey);
        
        // Desaciona o motor de som
        audioEngine.stopNote(midiNote, CURRENT_PRESET); 
        
        // Desativa a tecla visualmente
        const keyElement = document.querySelector(`[data-midi="${midiNote}"]`);
        if (keyElement) keyElement.classList.remove('active');

        pressedKeys.delete(pcKey);
    }
});

// 3. Funcionalidade Toggle Cifra
document.getElementById('toggle-cifra').addEventListener('click', (e) => {
    const labels = document.querySelectorAll('.cifra-label');
    const isVisible = labels[0].style.display === 'block';

    labels.forEach(label => {
        label.style.display = isVisible ? 'none' : 'block';
    });

    e.target.innerText = isVisible ? 'Mostrar Cifras (Desligado)' : 'Ocultar Cifras (Ligado)';
});

// --- INICIALIZAÇÃO ---
document.addEventListener('DOMContentLoaded', async () => {
    generateKeys();
    
    // Inicializa o Motor de Áudio
    audioEngine = new AudioEngine(MAX_VOICES);
    await audioEngine.initialize();
    
    console.log("Sistema Virtual Piano Stage totalmente operacional!");
});