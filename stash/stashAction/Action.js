
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
        // This method is run after the native code completes.
    
        var shortUrl = arguments["shortUrl"]
        alert('Your bit.ly link is now on your clipboard\n\n' + shortUrl);
    }
    
};

var ExtensionPreprocessingJS = new Action