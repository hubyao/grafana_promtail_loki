all:
	docekr-compose up -d
agent:
	docker-compose -f docker-compose-agent.yaml up -d 
