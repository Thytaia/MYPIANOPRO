/**
 * js/AudioEngine.js
 * Inicializa o Web Audio Context, o Gerenciador de Polifonia e o Signal Chain.
 */

class AudioEngine {
    constructor(maxVoices = 256) {
        // CORREÇÃO CRÍTICA DE ÁUDIO: O Contexto é criado e deve ser resumido por interação do usuário.
        this.context = new (window.AudioContext || window.webkitAudioContext)(); 
        this.maxVoices = maxVoices;
        
        // 1. Master Output
        this.masterGain = this.context.createGain();
        this.masterGain.gain.value = 0.7; // Volume inicial
        
        // 2. Módulo de Efeitos (Reverb/Chorus)
        this.effectModule = new EffectModule(this.context);
        
        // 3. Conexão Final: Efeitos -> Master -> Destino
        this.effectModule.connect(this.masterGain);
        this.masterGain.connect(this.context.destination);
        
        // 4. Inicializa o Gerenciador de Polifonia
        this.polyphonyManager = new PolyphonyManager(this.maxVoices, this.context, this.effectModule.input);
        
        // Garante que o contexto inicia em suspended (necessário para a correção em script.js)
        if (this.context.state === 'running') {
            this.context.suspend();
        }
    }

    // Função pública para iniciar o carregamento de samples (Fantasia)
    async initialize() {
        await this.polyphonyManager.loadSamples();
        console.log("Motor de Áudio e Samples carregados. Pronto para tocar.");
    }
    
    // Função pública para acionar notas (chamada pelo script.js)
    playNote(midiNote, presetID) {
        this.polyphonyManager.playNote(midiNote, presetID);
    }
    
    stopNote(midiNote, presetID) {
        this.polyphonyManager.stopNote(midiNote, presetID);
    }
}

// Instância única do Engine para uso global (inicializada no script.js)
let audioEngine;