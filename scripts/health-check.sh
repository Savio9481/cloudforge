URL="http://127.0.0.1:8000/health"

if curl -fsS "$URL" > /tmp/cloudforge-health.json; then
	    echo "CloudForge health check: HEALTHY"
	        cat /tmp/cloudforge-health.json
		    exit 0
	    else
		        echo "CloudForge health check: FAILED"
			    exit 1
fi
