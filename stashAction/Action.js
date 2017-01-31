
var Action = function() {};

Action.prototype = {
    
    run: function(arguments) {
        
        var links = document.links;
        var obj   = {};
        for (var i = 0; i < links.length; ++i) {
            obj[i] = links[i].href
        }
        
        arguments.completionFunction(obj)
    },
    
    finalize: function(arguments) {
    }
    
};

var ExtensionPreprocessingJS = new Action