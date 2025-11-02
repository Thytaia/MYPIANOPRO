/**
 * js/PresetBank.js
 * Banco de Dados de Timbres (Presets)
 * Contém parâmetros de voz, tipo de síntese e configuração de camadas (layers)
 */

const PresetBank = {
    // ------------------------------------------
    // 1. YAMAHA DX7 E. PIANO 1 (Timbre FM)
    // ------------------------------------------
    "DX7_E_PIANO_1": {
        id: "DX7_E_PIANO_1",
        name: "DX7 E. Piano 1",
        type: "FM",
        voiceClass: 'VoiceFM',
        // O motor de som usa 3 camadas por padrão para este timbre no teste de estresse
        layerCount: 3, 
        // Parâmetros FM simplificados para o protótipo:
        parameters: {
            algorithm: 6, // Exemplo de algoritmo que usa 2 carriers (tines)
            operators: [
                { ratio: 1.0, env: [0.01, 0.5, 0.5, 0.5] }, // Modulador principal
                { ratio: 1.41, env: [0.01, 0.5, 0.5, 0.5] }, // Modulador com offset (chorus)
                { ratio: 1.0, env: [0.01, 0.8, 0.5, 1.0] } // Carrier 1 (som principal)
                // Usar 6 operadores completos exigiria complexidade, 3 bastam para a prova de conceito
            ]
        }
    },

    // ------------------------------------------
    // 2. ROLAND FANTASIA PAD (Timbre Sampler)
    // ------------------------------------------
    "ROLAND_FANTASIA_PAD": {
        id: "ROLAND_FANTASIA_PAD",
        name: "Roland Fantasia Pad",
        type: "SAMPLE",
        voiceClass: 'VoiceSampler',
        // O motor de som usa 2 camadas por padrão para este timbre no teste de estresse
        layerCount: 2, 
        // URL do sample (deve ser colocado em assets/samples/)
        sampleURL: "assets/samples/fantasia_pad.wav", 
        envelopes: { 
            attack: 1.5,  // Attack lento
            release: 2.0  // Release longo e etéreo
        }
    },
    
    // ------------------------------------------
    // 3. YAMAHA MOTIF "POWER GRAND" (Placeholder)
    // ------------------------------------------
    "MOTIF_POWER_GRAND": {
        id: "MOTIF_POWER_GRAND",
        name: "Motif Power Grand",
        type: "SAMPLE",
        voiceClass: 'VoiceSampler',
        layerCount: 4, // Exemplo: 4 camadas para multi-sampling (próxima fase)
        sampleURL: "assets/samples/motif_power_grand_low.wav"
        // Esta voz exigirá multi-sampling e velocity-switching (Fase 7)
    }
};