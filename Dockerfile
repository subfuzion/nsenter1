FROM alpine:latest
ENTRYPOINT [ "nsenter", "-t", "1", "-m", "-u", "-n", "-i", "--" ]
CMD [ "sh" ]

