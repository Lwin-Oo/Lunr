//
//  LlamaBridge.mm
//  Lunr
//
//  Created by Lwin Oo on 5/20/25.
//

#import "LlamaBridge.h"
#import "LlamaRunner.h"

static LlamaRunner* runner = nullptr;

const char* classify_with_llama(const char* text) {
    if (!runner) {
        runner = new LlamaRunner("/absolute/path/to/your/gguf/model.gguf"); // 👈 update this
    }

    std::string input(text);
    std::string result = runner->classify(input);
    return strdup(result.c_str());
}
